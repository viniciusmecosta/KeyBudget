import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  static const _emailKey = 'last_user_email';
  static const _passwordKey = 'last_user_password';

  Future<bool> canAuthenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      return canAuthenticateWithBiometrics && availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    final bool canAuth = await canAuthenticate();
    if (!canAuth) return false;

    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: 'Confirme sua identidade',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: ' ',
            cancelButton: 'Cancelar',
            signInHint: ' ',
          ),
        ],
      );

      if (authenticated) {
        await HapticFeedback.lightImpact();
      } else {
        await HapticFeedback.vibrate();
      }

      return authenticated;
    } catch (e) {
      await HapticFeedback.vibrate();
      return false;
    }
  }

  Future<void> stopAuthentication() async {
    await _auth.stopAuthentication();
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<Map<String, String>?> getCredentials() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
