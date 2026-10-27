import 'package:passfin/core/security/vault_crypto.dart';

class EncryptionService {
  final VaultCipher? cipher;
  final String? userId;

  EncryptionService({this.cipher, this.userId});

  String encryptData(String plainText, {String? recordId}) => _activeCipher
      .encrypt(plainText, uid: _owner, recordId: _record(recordId));

  String decryptData(String encryptedText, {String? recordId}) => _activeCipher
      .decrypt(encryptedText, uid: _owner, recordId: _record(recordId));

  VaultCipher get _activeCipher =>
      cipher ??
      (throw const VaultException(
        VaultErrorCode.unavailable,
        'Abra o cofre pelo perfil para configurar ou recuperar a proteção.',
      ));

  String get _owner =>
      userId ??
      (throw const VaultException(
        VaultErrorCode.unavailable,
        'Sessão do cofre indisponível.',
      ));

  String _record(String? id) {
    if (id == null || id.isEmpty) {
      throw const VaultException(
        VaultErrorCode.unavailable,
        'Identificador da credencial indisponível.',
      );
    }
    return id;
  }
}
