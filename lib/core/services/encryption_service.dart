import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  final _key = encrypt.Key.fromUtf8('minha_chave_secreta_de_32_char');
  final _iv = encrypt.IV.fromLength(16); // IV para AES

  late final encrypt.Encrypter _encrypter;

  EncryptionService() {
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  String encryptData(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedText) {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
}
