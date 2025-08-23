import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() {
    return _instance;
  }
  EncryptionService._internal() {
    final keyString = dotenv.env['ENCRYPTION_KEY'];
    if (keyString == null || keyString.length != 32) {
      throw Exception(
        "ENCRYPTION_KEY not found or is not 32 characters long in .env file",
      );
    }
    final key = encrypt.Key.fromUtf8(keyString);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  late final encrypt.Encrypter _encrypter;
  final _iv = encrypt.IV.fromLength(16);

  String encryptData(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptData(String encryptedText) {
    final encrypted = encrypt.Encrypted.fromBase64(encryptedText);
    return _encrypter.decrypt(encrypted, iv: _iv);
  }
}
