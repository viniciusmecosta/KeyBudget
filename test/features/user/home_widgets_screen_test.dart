import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/app/config/app_theme.dart';
import 'package:passfin/core/models/home_widget_kind.dart';
import 'package:passfin/core/services/home_widget_service.dart';
import 'package:passfin/features/user/view/home_widgets_screen.dart';

void main() {
  const channel = MethodChannel('home_widget');
  final calls = <MethodCall>[];
  var supported = true;
  var fail = false;
  Completer<void>? pending;

  setUp(() {
    calls.clear();
    supported = true;
    fail = false;
    pending = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (fail) throw PlatformException(code: 'unavailable');
          if (call.method == 'isRequestPinWidgetSupported') return supported;
          await pending?.future;
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Future<void> pump(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const HomeWidgetsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('catalog offers every registered receiver exactly once', () {
    expect(
      HomeWidgetKind.values.map((kind) => kind.receiver),
      unorderedEquals(HomeWidgetService.androidWidgetNames),
    );
  });

  testWidgets('pin request opens confirmation without claiming installation', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Adicionar').first);
    await tester.pumpAndSettle();
    expect(calls.last.method, 'requestPinWidget');
    expect(calls.last.arguments['android'], HomeWidgetKind.compact.receiver);
    expect(find.textContaining('Confirme a inclusão'), findsOneWidget);
  });

  testWidgets('unsupported launcher shows manual instructions', (tester) async {
    supported = false;
    await pump(tester);
    await tester.tap(find.text('Adicionar').first);
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'requestPinWidget'), isEmpty);
    expect(
      find.textContaining('toque e segure um espaço vazio'),
      findsOneWidget,
    );
  });

  testWidgets('failure supports retry and does not overflow with 200% text', (
    tester,
  ) async {
    fail = true;
    await pump(tester, scale: 2);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('add-widget-compact')),
      180,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Não foi possível abrir'), findsOneWidget);
    expect(tester.takeException(), isNull);
    fail = false;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('add-widget-compact')),
      180,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Confirme a inclusão'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending request prevents duplicate submissions and survives disposal',
    (tester) async {
      pending = Completer<void>();
      await pump(tester);
      await tester.tap(find.text('Adicionar').first);
      await tester.pump();
      expect(
        calls.where((call) => call.method == 'requestPinWidget'),
        hasLength(1),
      );
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      pending!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
