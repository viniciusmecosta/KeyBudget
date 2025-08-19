import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionService {
  late final encrypt.Key _key;
  final _iv = encrypt.IV.fromLength(16);

  late final encrypt.Encrypter _encrypter;

  EncryptionService() {
    final keyString = dotenv.env['ENCRYPTION_KEY'];
    if (keyString == null || keyString.length != 32) {
      throw Exception(
        "ENCRYPTION_KEY not found or is not 32 characters long in .env file",
      );
    }
    _key = encrypt.Key.fromUtf8(keyString);
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
