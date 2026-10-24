import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/home_widget_service.dart';
import 'package:key_budget/core/services/home_widget_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = DateTime(2026, 12, 31, 12);
  HomeWidgetSnapshot snapshot(String uid) => HomeWidgetSnapshot.fromExpenses(
    userId: uid,
    now: today,
    showIncome: true,
    expenses: [
      Expense(amount: .1, date: today),
      Expense(amount: .2, date: today),
      Expense(amount: 50, date: today, isIncome: true),
      Expense(amount: 10, date: DateTime(2027, 1, 1)),
      Expense(amount: 20, date: DateTime(2027, 1, 7, 23)),
      Expense(amount: 900, date: DateTime(2027, 1, 8)),
      Expense(amount: 800, date: DateTime(2027, 1, 2), isIncome: true),
      Expense(amount: 700, date: DateTime(2026, 11, 30)),
    ],
  );

  test(
    'snapshot uses exact cents and calendar boundaries, not future income',
    () {
      final data = snapshot('user');
      expect(data.spentCents, 30);
      expect(data.incomeCents, 5000);
      expect(data.upcomingCents, 3000);
      expect(data.upcomingCount, 2);
      expect(data.toMap()['balance'], contains('49,70'));
      expect(data.toMap()['date'], '2026-12-31');
      expect(data.toMap()['version'], 2);
      expect(data.dailyTotals['2026-12-31'], [30, 5000, 2]);
      expect(data.dailyTotals['2027-01-01'], [1000, 0, 1]);
      expect(data.dailyTotals['2027-01-02'], [0, 80000, 0]);
      expect(data.toMap().toString(), isNot(contains('motivation')));
    },
  );

  group('widget session and refresh integration', () {
    final stored = <String, dynamic>{};
    final refreshed = <String>[];
    const channel = MethodChannel('home_widget');
    var failRefresh = false;
    setUp(() {
      failRefresh = false;
      stored.clear();
      refreshed.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final args = (call.arguments as Map?) ?? {};
            switch (call.method) {
              case 'getWidgetData':
                return stored[args['id']];
              case 'saveWidgetData':
                stored[args['id'] as String] = args['data'];
              case 'updateWidget':
                refreshed.add(args['name'] as String);
                if (failRefresh &&
                    args['name'] == HomeWidgetService.androidWidgetName) {
                  throw PlatformException(code: 'launcher_unavailable');
                }
            }
            return true;
          });
    });
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    test(
      'updates every variant with one complete account-scoped snapshot',
      () async {
        await HomeWidgetService.setWidgetSession('user');
        refreshed.clear();
        await HomeWidgetService.updateSnapshot(snapshot('user'));
        expect(refreshed, HomeWidgetService.androidWidgetNames);
        final data = jsonDecode(
          stored[HomeWidgetService.keySnapshot] as String,
        );
        expect(data['uid'], 'user');
        expect(data['spent'], contains('0,30'));
      },
    );

    test(
      'color changes refresh all widgets without replacing financial data',
      () async {
        await HomeWidgetService.setWidgetSession('user');
        await HomeWidgetService.updateSnapshot(snapshot('user'));
        final financial = stored[HomeWidgetService.keySnapshot];
        refreshed.clear();
        await HomeWidgetService.updateAppearance(
          'user',
          colorValue: 0xFF0F766E,
          mode: 'dark',
        );
        final appearance = stored[HomeWidgetService.keyAppearance];
        expect(jsonDecode(appearance as String)['mode'], 'dark');
        expect(stored[HomeWidgetService.keySnapshot], financial);
        expect(refreshed, HomeWidgetService.androidWidgetNames);
        refreshed.clear();
        await HomeWidgetService.updateAppearance(
          'user',
          colorValue: 0xFF0F766E,
          mode: 'dark',
        );
        expect(refreshed, isEmpty);
        await HomeWidgetService.updateAppearance(
          'old-user',
          colorValue: 0xFF7C3AED,
        );
        expect(stored[HomeWidgetService.keyAppearance], appearance);
        await HomeWidgetService.clearWidgetData();
        await HomeWidgetService.updateAppearance(
          'user',
          colorValue: 0xFF7C3AED,
        );
        expect(stored[HomeWidgetService.keyAppearance], '');
      },
    );

    test(
      'session restores colors and ignores unchanged profile events',
      () async {
        await HomeWidgetService.setWidgetSession(
          'user',
          colorValue: 0xFF7C3AED,
          mode: 'light',
        );
        final first = stored[HomeWidgetService.keyAppearance];
        refreshed.clear();
        await HomeWidgetService.setWidgetSession(
          'user',
          colorValue: 0xFF7C3AED,
          mode: 'light',
        );
        expect(refreshed, isEmpty);
        await HomeWidgetService.setWidgetSession(
          'other',
          colorValue: 0xFF0F766E,
        );
        expect(stored[HomeWidgetService.keyAppearance], isNot(first));
        expect(
          jsonDecode(stored[HomeWidgetService.keyAppearance] as String)['mode'],
          'system',
        );
      },
    );

    test(
      'failed refresh retries the same saved appearance for all providers',
      () async {
        await HomeWidgetService.setWidgetSession('user');
        failRefresh = true;
        refreshed.clear();
        await HomeWidgetService.updateAppearance(
          'user',
          colorValue: 0xFF7C3AED,
        );
        expect(refreshed, HomeWidgetService.androidWidgetNames);
        failRefresh = false;
        refreshed.clear();
        await HomeWidgetService.updateAppearance(
          'user',
          colorValue: 0xFF7C3AED,
        );
        expect(refreshed, HomeWidgetService.androidWidgetNames);
      },
    );

    test('logout wins when a snapshot update is already queued', () async {
      await HomeWidgetService.setWidgetSession('user');
      final update = HomeWidgetService.updateSnapshot(snapshot('user'));
      final logout = HomeWidgetService.clearWidgetData();
      await Future.wait([update, logout]);
      expect(stored[HomeWidgetService.keySnapshot], '');
      expect(stored[HomeWidgetService.keyUserId], '');
    });

    test(
      'late updates from a previous account are ignored and logout clears data',
      () async {
        await HomeWidgetService.setWidgetSession('user');
        await HomeWidgetService.updateSnapshot(snapshot('user'));
        await HomeWidgetService.setWidgetSession('other');
        expect(stored[HomeWidgetService.keySnapshot], '');
        await HomeWidgetService.updateSnapshot(snapshot('user'));
        expect(stored[HomeWidgetService.keySnapshot], '');
        await HomeWidgetService.updateSnapshot(snapshot('other'));
        await HomeWidgetService.clearWidgetData();
        await HomeWidgetService.updateSnapshot(snapshot('other'));
        expect(stored[HomeWidgetService.keySnapshot], '');
        expect(stored[HomeWidgetService.keyUserId], '');
        expect(stored[HomeWidgetService.keyStatus], 'logged_out');
      },
    );
  });
}
