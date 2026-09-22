import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pointycastle/export.dart';

class BackupCryptoException implements Exception {
  final String message;
  const BackupCryptoException(this.message);

  @override
  String toString() => 'BackupCryptoException: $message';
}

class BackupSecurityException implements Exception {
  final String message;
  const BackupSecurityException(this.message);

  @override
  String toString() => 'BackupSecurityException: $message';
}

class BackupCrypto {
  static const List<int> magicBytes = [0x4B, 0x42, 0x47, 0x31];
  static const int currentFormatVersion = 1;
  static const int defaultIterations = 50000;
  static const int minIterations = 10000;
  static const int maxIterations = 500000;
  static const int saltBytesCount = 16;
  static const int nonceBytesCount = 12;
  static const int macBitsCount = 128;

  static const int maxDecompressedBytesLimit = 200 * 1024 * 1024;
  static const int maxArchiveEntriesLimit = 2000;

  static Uint8List packArchive(Map<String, List<int>> files) {
    final archive = Archive();
    for (final entry in files.entries) {
      final name = entry.key;
      final bytes = entry.value;
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    final zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes);
  }

  static Map<String, List<int>> unpackArchive(
    Uint8List zipBytes, {
    int maxTotalBytes = maxDecompressedBytesLimit,
    int maxEntries = maxArchiveEntriesLimit,
  }) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (e) {
      throw BackupSecurityException('Pacote ZIP corrompido ou malformado: $e');
    }

    if (archive.length > maxEntries) {
      throw BackupSecurityException(
        'Número de arquivos no pacote (${archive.length}) excede o limite máximo permitido ($maxEntries).',
      );
    }

    final Map<String, List<int>> result = {};
    final Set<String> seenPaths = {};
    int totalDecompressedBytes = 0;

    for (final file in archive) {
      if (!file.isFile) continue;

      final name = file.name;

      if (name.startsWith('/') ||
          name.startsWith('\\') ||
          name.contains('../') ||
          name.contains('..\\') ||
          name.contains('~/')) {
        throw BackupSecurityException(
          'Tentativa de path traversal detectada no caminho: "$name"',
        );
      }

      if (!seenPaths.add(name)) {
        throw BackupSecurityException(
          'Entrada duplicada detectada no pacote: "$name"',
        );
      }

      final content = file.content as List<int>;
      totalDecompressedBytes += content.length;

      if (totalDecompressedBytes > maxTotalBytes) {
        throw BackupSecurityException(
          'Tamanho total descompactado excede o limite seguro de $maxTotalBytes bytes.',
        );
      }

      result[name] = content;
    }

    return result;
  }

  static Uint8List encryptEnvelope({
    required Uint8List payload,
    required String password,
    int iterations = defaultIterations,
  }) {
    if (password.isEmpty) {
      throw BackupCryptoException('A senha do backup não pode ser vazia.');
    }
    if (iterations < minIterations || iterations > maxIterations) {
      throw BackupCryptoException(
        'Número de iterações inválido: $iterations. Deve estar entre $minIterations e $maxIterations.',
      );
    }

    final random = Random.secure();

    final salt = Uint8List(saltBytesCount);
    for (int i = 0; i < saltBytesCount; i++) {
      salt[i] = random.nextInt(256);
    }

    final nonce = Uint8List(nonceBytesCount);
    for (int i = 0; i < nonceBytesCount; i++) {
      nonce[i] = random.nextInt(256);
    }

    final headerBuilder = BytesBuilder();
    headerBuilder.add(magicBytes);

    final versionData = ByteData(2)..setUint16(0, currentFormatVersion, Endian.big);
    headerBuilder.add(versionData.buffer.asUint8List());

    final iterData = ByteData(4)..setUint32(0, iterations, Endian.big);
    headerBuilder.add(iterData.buffer.asUint8List());

    headerBuilder.addByte(salt.length);
    headerBuilder.add(salt);

    headerBuilder.addByte(nonce.length);
    headerBuilder.add(nonce);

    final headerBytes = headerBuilder.toBytes();

    final kdf = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    kdf.init(Pbkdf2Parameters(salt, iterations, 32));
    final derivedKey = kdf.process(Uint8List.fromList(password.codeUnits));

    final cipher = GCMBlockCipher(AESEngine());
    final aeadParams = AEADParameters(
      KeyParameter(derivedKey),
      macBitsCount,
      nonce,
      headerBytes,
    );
    cipher.init(true, aeadParams);

    final ciphertext = cipher.process(payload);

    final envelopeBuilder = BytesBuilder();
    envelopeBuilder.add(headerBytes);
    envelopeBuilder.add(ciphertext);

    return envelopeBuilder.toBytes();
  }

  static Uint8List decryptEnvelope({
    required Uint8List envelope,
    required String password,
  }) {
    if (password.isEmpty) {
      throw BackupCryptoException('A senha do backup não pode ser vazia.');
    }

    if (envelope.length < 56) {
      throw const BackupCryptoException(
        'Arquivo de backup inválido: tamanho insuficiente.',
      );
    }

    for (int i = 0; i < 4; i++) {
      if (envelope[i] != magicBytes[i]) {
        throw const BackupCryptoException(
          'Arquivo de backup inválido ou formato não reconhecido.',
        );
      }
    }

    final byteData = ByteData.sublistView(envelope);
    final version = byteData.getUint16(4, Endian.big);
    if (version > currentFormatVersion) {
      throw BackupCryptoException(
        'Versão do formato de backup não suportada: $version. Atualize o aplicativo para restaurar este arquivo.',
      );
    }
    if (version < 1) {
      throw const BackupCryptoException('Versão de backup inválida.');
    }

    final iterations = byteData.getUint32(6, Endian.big);
    if (iterations < minIterations || iterations > maxIterations) {
      throw BackupCryptoException(
        'Parâmetros de derivação de chave fora dos limites seguros aceitos: $iterations.',
      );
    }

    int offset = 10;
    final saltLen = envelope[offset++];
    if (saltLen < 8 || saltLen > 64 || offset + saltLen > envelope.length) {
      throw const BackupCryptoException('Parâmetro de salt inválido.');
    }
    final salt = Uint8List.sublistView(envelope, offset, offset + saltLen);
    offset += saltLen;

    final nonceLen = envelope[offset++];
    if (nonceLen != nonceBytesCount || offset + nonceLen > envelope.length) {
      throw const BackupCryptoException('Parâmetro de nonce/IV inválido.');
    }
    final nonce = Uint8List.sublistView(envelope, offset, offset + nonceLen);
    offset += nonceLen;

    final headerBytes = Uint8List.sublistView(envelope, 0, offset);
    final ciphertext = Uint8List.sublistView(envelope, offset);

    final kdf = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    kdf.init(Pbkdf2Parameters(salt, iterations, 32));
    final derivedKey = kdf.process(Uint8List.fromList(password.codeUnits));

    try {
      final cipher = GCMBlockCipher(AESEngine());
      final aeadParams = AEADParameters(
        KeyParameter(derivedKey),
        macBitsCount,
        nonce,
        headerBytes,
      );
      cipher.init(false, aeadParams);
      final plaintext = cipher.process(ciphertext);
      return plaintext;
    } on InvalidCipherTextException {
      throw const BackupCryptoException(
        'Senha incorreta ou arquivo de backup adulterado/corrompido.',
      );
    } catch (e) {
      throw BackupCryptoException(
        'Falha na descriptografia do backup: $e',
      );
    }
  }
}
