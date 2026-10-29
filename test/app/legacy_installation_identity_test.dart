import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/services/home_widget_service.dart';

void main() {
  test('PassFin remains an upgrade of the legacy Android installation', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "com.vinicius.key_budget"'));
    expect(gradle, contains('namespace = "com.vinicius.key_budget"'));
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    for (final receiver in HomeWidgetService.androidWidgetNames) {
      expect(manifest, contains('android:name=".$receiver"'));
    }
    expect(manifest, contains('android:scheme="keybudget"'));
    expect(manifest, contains('android:scheme="passfin"'));
  });
}
