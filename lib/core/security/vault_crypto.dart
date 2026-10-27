import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as legacy;
import 'package:pointycastle/export.dart';

enum VaultErrorCode {
  invalidLegacyKey,
  malformedEnvelope,
  unsupportedFormat,
  unknownKey,
  unavailable,
  authenticationFailed,
  conflict,
  invalidBackup,
  confirmationRequired,
}

class VaultException implements Exception {
  final VaultErrorCode code;
  final String message;

  const VaultException(this.code, this.message);

  @override
  String toString() => message;
}

String normalizeLegacyKey(String input) {
  final value = input.trim();
  if (value.length != 32 || utf8.encode(value).length != 32) {
    throw const VaultException(
      VaultErrorCode.invalidLegacyKey,
      'Informe somente o valor da chave antiga: 32 caracteres e 32 bytes em UTF-8.',
    );
  }
  if (RegExp(r'[\x00-\x1F\x7F]').hasMatch(value)) {
    throw const VaultException(
      VaultErrorCode.invalidLegacyKey,
      'A chave não pode conter quebras de linha ou controles internos.',
    );
  }
  return value;
}

Uint8List vaultRandomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

class LegacyVaultReader {
  final legacy.Encrypter _cipher;

  LegacyVaultReader(String input)
    : _cipher = legacy.Encrypter(
        legacy.AES(
          legacy.Key.fromUtf8(normalizeLegacyKey(input)),
          mode: legacy.AESMode.sic,
          padding: 'PKCS7',
        ),
      );

  String decrypt(String value) {
    try {
      final parts = value.split(':');
      if (parts.length != 2) throw const FormatException();
      final iv = base64.decode(parts[0]);
      final bytes = base64.decode(parts[1]);
      if (iv.length != 16 || bytes.isEmpty || bytes.length % 16 != 0) {
        throw const FormatException();
      }
      return utf8.decode(
        _cipher.decryptBytes(legacy.Encrypted(bytes), iv: legacy.IV(iv)),
        allowMalformed: false,
      );
    } catch (_) {
      throw const VaultException(
        VaultErrorCode.invalidLegacyKey,
        'Não foi possível ler a senha com essa chave. Confira a chave antiga.',
      );
    }
  }
}

class VaultCipher {
  static const maxPasswordBytes = 64 * 1024;
  static const maxEnvelopeCharacters = 128 * 1024;
  final String keyId;
  final Uint8List _key;

  VaultCipher({required this.keyId, required List<int> key})
    : _key = Uint8List.fromList(key) {
    if (keyId.isEmpty || _key.length != 32) {
      throw const VaultException(
        VaultErrorCode.unknownKey,
        'Chave do cofre inválida.',
      );
    }
  }

  Uint8List _aad(String uid, String recordId) {
    if (uid.isEmpty || recordId.isEmpty) {
      throw const VaultException(
        VaultErrorCode.unavailable,
        'Registro do cofre inválido.',
      );
    }
    return Uint8List.fromList(
      utf8.encode(
        jsonEncode([
          'keybudget-vault',
          2,
          'A256GCM',
          keyId,
          uid,
          recordId,
          'encrypted_password',
        ]),
      ),
    );
  }

  Uint8List seal(List<int> input, List<int> aad, {List<int>? nonce}) {
    final iv = nonce == null ? vaultRandomBytes(12) : Uint8List.fromList(nonce);
    if (iv.length != 12) {
      throw const VaultException(
        VaultErrorCode.malformedEnvelope,
        'Nonce inválido.',
      );
    }
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(_key), 128, iv, Uint8List.fromList(aad)),
      );
    return Uint8List.fromList([
      ...iv,
      ...cipher.process(Uint8List.fromList(input)),
    ]);
  }

  Uint8List open(List<int> input, List<int> aad) {
    if (input.length < 28) {
      throw const VaultException(
        VaultErrorCode.malformedEnvelope,
        'Conteúdo criptografado inválido.',
      );
    }
    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(_key),
            128,
            Uint8List.fromList(input.sublist(0, 12)),
            Uint8List.fromList(aad),
          ),
        );
      return cipher.process(Uint8List.fromList(input.sublist(12)));
    } catch (_) {
      throw const VaultException(
        VaultErrorCode.authenticationFailed,
        'Não foi possível autenticar o conteúdo do cofre.',
      );
    }
  }

  String encrypt(
    String plaintext, {
    required String uid,
    required String recordId,
  }) {
    final bytes = utf8.encode(plaintext);
    if (bytes.length > maxPasswordBytes) {
      throw const VaultException(
        VaultErrorCode.malformedEnvelope,
        'A senha excede o limite de 64 KiB.',
      );
    }
    final sealed = seal(bytes, _aad(uid, recordId));
    final body = {
      'v': 2,
      'alg': 'A256GCM',
      'kid': keyId,
      'nonce': base64Url.encode(sealed.sublist(0, 12)),
      'ct': base64Url.encode(sealed.sublist(12, sealed.length - 16)),
      'tag': base64Url.encode(sealed.sublist(sealed.length - 16)),
    };
    return 'kbv2.${base64Url.encode(utf8.encode(jsonEncode(body)))}';
  }

  String decrypt(
    String value, {
    required String uid,
    required String recordId,
  }) {
    try {
      if (!value.startsWith('kbv2.')) {
        throw const VaultException(
          VaultErrorCode.unsupportedFormat,
          'Formato do cofre não suportado.',
        );
      }
      if (value.length > maxEnvelopeCharacters) throw const FormatException();
      final body = jsonDecode(
        utf8.decode(base64Url.decode(value.substring(5))),
      );
      if (body is! Map<String, dynamic> ||
          body.length != 6 ||
          !body.keys.toSet().containsAll({
            'v',
            'alg',
            'kid',
            'nonce',
            'ct',
            'tag',
          })) {
        throw const FormatException();
      }
      if (body['v'] != 2 || body['v'] is! int || body['alg'] != 'A256GCM') {
        throw const VaultException(
          VaultErrorCode.unsupportedFormat,
          'Versão criptográfica não suportada.',
        );
      }
      if (body['kid'] != keyId) {
        throw const VaultException(
          VaultErrorCode.unknownKey,
          'A chave desta senha não está disponível.',
        );
      }
      final nonce = base64Url.decode(body['nonce'] as String);
      final ciphertext = base64Url.decode(body['ct'] as String);
      final tag = base64Url.decode(body['tag'] as String);
      if (nonce.length != 12 ||
          tag.length != 16 ||
          ciphertext.length > maxPasswordBytes) {
        throw const FormatException();
      }
      return utf8.decode(
        open([...nonce, ...ciphertext, ...tag], _aad(uid, recordId)),
      );
    } on VaultException {
      rethrow;
    } catch (_) {
      throw const VaultException(
        VaultErrorCode.malformedEnvelope,
        'Formato da senha inválido.',
      );
    }
  }

  void dispose() => _key.fillRange(0, _key.length, 0);
}
