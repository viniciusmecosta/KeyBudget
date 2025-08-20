import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  static const _lastUserKey = 'last_user_id';

  Future<void> saveLastUser(String userId) async {
    await _storage.write(key: _lastUserKey, value: userId);
  }

  Future<String?> getLastUser() async {
    return await _storage.read(key: _lastUserKey);
  }

  Future<void> clearLastUser() async {
    await _storage.delete(key: _lastUserKey);
  }

  Future<bool> authenticate() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return false;
      }
      return await _localAuth.authenticate(
        localizedReason: 'Autentique para acessar o KeyBudget',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
