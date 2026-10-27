import 'dart:convert';
import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/security/vault_crypto.dart';

void main() {
  test(
    'legacy input trims edges and preserves punctuation and internal spaces',
    () {
      const special = r'abcdefghijklmnopqrstuvwx!@#$%&*?';
      expect(normalizeLegacyKey('  $special\n'), special);
      final spaced = 'A B${List.filled(29, 'x').join()}';
      expect(normalizeLegacyKey(spaced), spaced);
      for (final input in [
        '',
        'a' * 31,
        'a' * 33,
        'á' * 32,
        '${'a' * 15}\t${'b' * 16}',
      ]) {
        expect(() => normalizeLegacyKey(input), throwsA(isA<VaultException>()));
      }
    },
  );

  test('legacy SIC PKCS7 remains readable without sentinel passwords', () {
    const key = '12345678901234567890123456789012';
    final cipher = legacy.Encrypter(legacy.AES(legacy.Key.fromUtf8(key)));
    final iv = legacy.IV.fromLength(16);
    final ciphertext = cipher.encrypt('ERRO_DECRIPT', iv: iv);
    expect(
      LegacyVaultReader(key).decrypt('${iv.base64}:${ciphertext.base64}'),
      'ERRO_DECRIPT',
    );
    expect(
      () => LegacyVaultReader(key).decrypt('invalid'),
      throwsA(isA<VaultException>()),
    );
  });

  test('AES256 GCM matches independent known answer and rejects tampering', () {
    final cipher = VaultCipher(keyId: 'key', key: List.filled(32, 0));
    final bytes = cipher.seal(
      List.filled(16, 0),
      [],
      nonce: List.filled(12, 0),
    );
    expect(
      bytes.sublist(12).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      'cea7403d4d606b6e074ec5d3baf39d18d0d1c8a799996bf0265b98b5d48ab919',
    );
    bytes[12] ^= 1;
    expect(() => cipher.open(bytes, []), throwsA(isA<VaultException>()));
  });

  test('passwords authenticate owner record and envelope metadata', () {
    final cipher = VaultCipher(keyId: 'key-a', key: List.filled(32, 9));
    for (final plain in ['', 'ERRO_DECRIPT', 'á🔑\n']) {
      final value = cipher.encrypt(plain, uid: 'a', recordId: 'one');
      expect(cipher.decrypt(value, uid: 'a', recordId: 'one'), plain);
      expect(
        () => cipher.decrypt(value, uid: 'b', recordId: 'one'),
        throwsA(isA<VaultException>()),
      );
      expect(
        () => cipher.decrypt(value, uid: 'a', recordId: 'two'),
        throwsA(isA<VaultException>()),
      );
      final body =
          jsonDecode(utf8.decode(base64Url.decode(value.substring(5))))
              as Map<String, dynamic>;
      for (final field in ['nonce', 'ct', 'tag']) {
        final modified = Map<String, dynamic>.from(body);
        final bytes = base64Url.decode(modified[field] as String);
        if (bytes.isEmpty) continue;
        bytes[0] ^= 1;
        modified[field] = base64Url.encode(bytes);
        final tampered =
            'kbv2.${base64Url.encode(utf8.encode(jsonEncode(modified)))}';
        expect(
          () => cipher.decrypt(tampered, uid: 'a', recordId: 'one'),
          throwsA(isA<VaultException>()),
        );
      }
    }
    expect(
      cipher.encrypt('same', uid: 'a', recordId: 'one'),
      isNot(cipher.encrypt('same', uid: 'a', recordId: 'one')),
    );
    expect(
      () => cipher.decrypt('kbv3.invalid', uid: 'a', recordId: 'one'),
      throwsA(isA<VaultException>()),
    );
  });
}
