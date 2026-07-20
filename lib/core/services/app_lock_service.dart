import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

class AppLockService extends ChangeNotifier {
  bool _isLocked = false;
  bool _justUnlocked = false;
  bool isAuthenticating = false;

  /// Ativo somente durante abertura de seletores externos (file picker, câmera, etc).
  /// Enquanto true, lockApp() é ignorado para não travar o app ao voltar do seletor.
  bool _isExternalPickerActive = false;

  bool get isLocked => _isLocked;

  bool get justUnlocked => _justUnlocked;

  /// Sinaliza que um seletor externo vai ser aberto — lockApp() será ignorado até endExternalPick().
  void beginExternalPick() {
    _isExternalPickerActive = true;
  }

  /// Sinaliza que voltou do seletor — lockApp() volta a funcionar normalmente.
  void endExternalPick() {
    _isExternalPickerActive = false;
  }

  void lockApp() {
    if (isAuthenticating) return;
    if (_isExternalPickerActive) return;
    if (!_isLocked) {
      _isLocked = true;
      _justUnlocked = false;
      notifyListeners();
    }
  }

  void unlockApp() {
    if (_isLocked) {
      _isLocked = false;
      _justUnlocked = true;
      _isExternalPickerActive = false;
      notifyListeners();
    }
  }

  void consumeJustUnlocked() {
    if (_justUnlocked) {
      _justUnlocked = false;
    }
  }

  void resetIfStuck() {
    if (isAuthenticating) {
      isAuthenticating = false;
    }
  }
}

final appLockServiceProvider = ChangeNotifierProvider<AppLockService>(
  (ref) => AppLockService(),
);
