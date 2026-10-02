import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

enum LocalAuthAvailability {
  supported,
  deviceCredentialOnly,
  noBiometricsEnrolled,
  notSupported,
}

enum LocalAuthResult {
  success,
  cancelled,
  temporarilyLockedOut,
  permanentlyLockedOut,
  notAvailable,
  failed,
}

class LocalAuthService {
  final LocalAuthentication _auth;
  final FlutterSecureStorage _storage;
  static const _emailKey = 'last_user_email';
  static const _passwordKey = 'last_user_password';

  LocalAuthService({
    LocalAuthentication? auth,
    FlutterSecureStorage? storage,
  })  : _auth = auth ?? LocalAuthentication(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<bool> canAuthenticate() async {
    try {
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      return isDeviceSupported || canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<LocalAuthAvailability> checkAvailability() async {
    try {
      final bool isSupported = await _auth.isDeviceSupported();
      final bool canCheck = await _auth.canCheckBiometrics;
      if (!isSupported && !canCheck) {
        return LocalAuthAvailability.notSupported;
      }

      final List<BiometricType> biometrics =
          await _auth.getAvailableBiometrics();
      if (biometrics.isNotEmpty) {
        return LocalAuthAvailability.supported;
      }
      if (isSupported) {
        return LocalAuthAvailability.deviceCredentialOnly;
      }
      return LocalAuthAvailability.noBiometricsEnrolled;
    } catch (_) {
      return LocalAuthAvailability.notSupported;
    }
  }

  Future<LocalAuthResult> authenticateLocal({
    String reason = 'Confirme sua identidade',
  }) async {
    final bool canAuth = await canAuthenticate();
    if (!canAuth) return LocalAuthResult.notAvailable;

    try {
      final bool authenticated = await _auth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Confirme sua identidade',
            cancelButton: 'Cancelar',
            signInHint: 'Toque no sensor biométrico ou use sua senha',
          ),
        ],
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );

      if (authenticated) {
        await HapticFeedback.lightImpact();
        return LocalAuthResult.success;
      } else {
        return LocalAuthResult.failed;
      }
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.timeout:
          return LocalAuthResult.cancelled;
        case LocalAuthExceptionCode.temporaryLockout:
          return LocalAuthResult.temporarilyLockedOut;
        case LocalAuthExceptionCode.biometricLockout:
          return LocalAuthResult.permanentlyLockedOut;
        case LocalAuthExceptionCode.noCredentialsSet:
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
          return LocalAuthResult.notAvailable;
        default:
          return LocalAuthResult.failed;
      }
    } on PlatformException catch (e) {
      if (e.code == 'UserCanceled' ||
          e.code == 'SystemCanceled' ||
          e.code == 'Canceled') {
        return LocalAuthResult.cancelled;
      } else if (e.code == 'LockedOut') {
        return LocalAuthResult.temporarilyLockedOut;
      } else if (e.code == 'PermanentlyLockedOut') {
        return LocalAuthResult.permanentlyLockedOut;
      } else if (e.code == 'NotAvailable') {
        return LocalAuthResult.notAvailable;
      }
      return LocalAuthResult.failed;
    } catch (_) {
      return LocalAuthResult.failed;
    }
  }

  Future<bool> authenticate() async {
    final result = await authenticateLocal();
    return result == LocalAuthResult.success;
  }

  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }

  Future<void> saveCredentials(String email, String password) async {

  }

  Future<Map<String, String>?> getCredentials() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error reading credentials: $e");
      }
    }
    return null;
  }

  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
    } catch (e) {
      if (kDebugMode) {
        print("Error clearing legacy credentials: $e");
      }
    }
  }
}
