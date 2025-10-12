import 'package:flutter/material.dart';

class AppLockService extends ChangeNotifier {
  bool _isLocked = false;
  bool _justUnlocked = false;

  bool get isLocked => _isLocked;

  bool get justUnlocked => _justUnlocked;

  void lockApp() {
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
      notifyListeners();
    }
  }

  void consumeJustUnlocked() {
    if (_justUnlocked) {
      _justUnlocked = false;
    }
  }
}
