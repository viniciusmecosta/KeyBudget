import 'dart:async';
import 'package:flutter/material.dart';

class AppLockService extends ChangeNotifier {
  bool _isLocked = false;
  Timer? _lockTimer;

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

  void startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer(const Duration(seconds: 15), () {
      lockApp();
    });
  }

  void cancelLockTimer() {
    _lockTimer?.cancel();
  }
}
