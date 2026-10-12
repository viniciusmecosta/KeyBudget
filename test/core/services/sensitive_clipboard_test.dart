import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/services/sensitive_clipboard.dart';

void main() {
  testWidgets('password expires without replacing a newer clipboard value', (
    tester,
  ) async {
    String? clipboard;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          } else if (call.method == 'Clipboard.getData') {
            return {'text': clipboard};
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await SensitiveClipboard.copyPassword('segredo');
    expect(clipboard, 'segredo');
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(clipboard, '');

    await SensitiveClipboard.copyPassword('outro segredo');
    clipboard = 'texto novo';
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(clipboard, 'texto novo');
  });
}
