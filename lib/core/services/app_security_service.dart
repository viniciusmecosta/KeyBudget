import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppSecurityService {
  static const MethodChannel _channel = MethodChannel('app_security');

  static Future<void> setSecure(bool secure) async {
    try {
      await _channel.invokeMethod('setSecure', {'secure': secure});
    } on PlatformException catch (e) {
      debugPrint("Failed to set secure mode: '${e.message}'.");
    }
  }
}
