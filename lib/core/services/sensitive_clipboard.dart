import 'dart:async';

import 'package:flutter/services.dart';

class SensitiveClipboard {
  static Timer? _clearTimer;

  static Future<void> copyPassword(String password) async {
    _clearTimer?.cancel();
    await Clipboard.setData(ClipboardData(text: password));
    _clearTimer = Timer(const Duration(seconds: 30), () async {
      try {
        final data = await Clipboard.getData('text/plain');
        if (data?.text == password) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } on PlatformException {
        return;
      }
    });
  }
}
