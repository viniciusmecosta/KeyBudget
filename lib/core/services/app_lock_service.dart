import 'package:flutter/material.dart';

class AppLockService extends ChangeNotifier {
  bool _isLocked = false;

  bool get isLocked => _isLocked;

  void lockApp() {
    if (!_isLocked) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    if (_isLocked) {
      _isLocked = false;
      notifyListeners();
    }
  }
}
