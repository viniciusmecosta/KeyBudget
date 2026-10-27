import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'home_widget_appearance.dart';
import 'home_widget_snapshot.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.vinicius.keybudget';
  static const String iOSWidgetName = 'KeyBudgetWidget';
  static const String androidWidgetName = 'KeyBudgetWidgetReceiver';

  static const androidWidgetNames = [
    androidWidgetName,
    'KeyBudgetCompactWidgetReceiver',
    'KeyBudgetOverviewWidgetReceiver',
    'KeyBudgetUpcomingWidgetReceiver',
    'KeyBudgetQuickWidgetReceiver',
  ];
  static const keySnapshot = 'widget_snapshot';
  static const keyAppearance = 'widget_appearance';

  static Future<void> _refreshAll() async {
    // Refresh every provider even when one launcher update fails.
    await Future.wait([
      for (final name in androidWidgetNames)
        HomeWidget.updateWidget(name: name, iOSName: iOSWidgetName),
    ]);
  }

  static String? _lastRefreshedProfile;

  static Future<void> _pendingWrite = Future.value();

  static Future<void> _serialize(Future<void> Function() operation) {
    final next = _pendingWrite.then((_) => operation());
    _pendingWrite = next.catchError((Object error) {
      debugPrint('Não foi possível salvar os widgets: ${error.runtimeType}');
    });
    return _pendingWrite;
  }

  static Future<void> updateSnapshot(HomeWidgetSnapshot snapshot) =>
      _serialize(() async {
        try {
          final activeUid = await HomeWidget.getWidgetData<String>(keyUserId);
          if (activeUid != snapshot.userId || snapshot.userId.isEmpty) return;
          await HomeWidget.saveWidgetData<String>(
            keySnapshot,
            jsonEncode(snapshot.toMap()),
          );
          await _refreshAll();
        } catch (error) {
          debugPrint(
            'Não foi possível atualizar os widgets: ${error.runtimeType}',
          );
        }
      });

  static const String keyWidgetVersion = 'widget_version';
  static const String keyUserId = 'widget_user_id';
  static const String keyReferenceMonth = 'widget_reference_month';
  static const String keyShowValues = 'widget_show_values';
  static const String keyMonthlySpent = 'monthly_spent';
  static const String keyMonthlySpentCents = 'monthly_spent_cents';
  static const String keyStatus = 'widget_status';
  static const String keyUpdatedAt = 'widget_updated_at';

  static Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {}
  }

  static bool? _cachedShowValues;

  static Future<bool> getShowValues() async {
    if (_cachedShowValues != null) return _cachedShowValues!;
    try {
      final value = await HomeWidget.getWidgetData<bool>(keyShowValues);
      _cachedShowValues = value ?? false;
      return _cachedShowValues!;
    } catch (_) {
      return _cachedShowValues ?? false;
    }
  }

  static Future<void> setShowValues(bool show) async {
    _cachedShowValues = show;
    try {
      await HomeWidget.saveWidgetData<bool>(keyShowValues, show);
    } catch (_) {}
  }

  static Future<void> setWidgetSession(
    String uid, {
    int? colorValue,
    String mode = 'system',
  }) => _serialize(() async {
    if (uid.isEmpty) return;
    final appearance = jsonEncode(
      HomeWidgetAppearance.toMap(colorValue: colorValue, mode: mode),
    );
    final previous = await HomeWidget.getWidgetData<String>(keyUserId);
    final previousAppearance = await HomeWidget.getWidgetData<String>(
      keyAppearance,
    );
    final status = await HomeWidget.getWidgetData<String>(keyStatus);
    if (previous == uid &&
        previousAppearance == appearance &&
        status == 'active' &&
        _lastRefreshedProfile == '$uid:$appearance') {
      return;
    }
    if (previous != uid) {
      await HomeWidget.saveWidgetData<String>(keySnapshot, '');
    }
    await HomeWidget.saveWidgetData<String>(keyAppearance, appearance);
    await HomeWidget.saveWidgetData<String>(keyUserId, uid);
    await HomeWidget.saveWidgetData<String>(keyStatus, 'active');
    await _refreshAll();
    _lastRefreshedProfile = '$uid:$appearance';
  });

  static Future<void> updateAppearance(
    String uid, {
    int? colorValue,
    String mode = 'system',
  }) => _serialize(() async {
    if (uid.isEmpty ||
        await HomeWidget.getWidgetData<String>(keyUserId) != uid) {
      return;
    }
    final appearance = jsonEncode(
      HomeWidgetAppearance.toMap(colorValue: colorValue, mode: mode),
    );
    if (await HomeWidget.getWidgetData<String>(keyAppearance) == appearance &&
        _lastRefreshedProfile == '$uid:$appearance') {
      return;
    }
    await HomeWidget.saveWidgetData<String>(keyAppearance, appearance);
    await _refreshAll();
    _lastRefreshedProfile = '$uid:$appearance';
  });

  static Future<void> updateWidgetData(
    double monthlySpent, {
    String? uid,
    DateTime? referenceMonth,
    bool? showValuesOverride,
  }) async {
    try {
      final refDate = referenceMonth ?? DateTime.now();
      final monthStr = DateFormat('yyyy-MM').format(refDate);

      final cents = (monthlySpent * 100).round();

      final currencyFormatter = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
        decimalDigits: 2,
      );

      final formattedAmount = currencyFormatter.format(monthlySpent);

      await HomeWidget.saveWidgetData<int>(keyWidgetVersion, 1);
      if (uid != null && uid.isNotEmpty) {
        await HomeWidget.saveWidgetData<String>(keyUserId, uid);
        await HomeWidget.saveWidgetData<String>(keyStatus, 'active');
      }
      await HomeWidget.saveWidgetData<String>(keyReferenceMonth, monthStr);
      await HomeWidget.saveWidgetData<bool>(
        keyShowValues,
        showValuesOverride ?? false,
      );
      await HomeWidget.saveWidgetData<String>(keyMonthlySpent, formattedAmount);
      await HomeWidget.saveWidgetData<int>(keyMonthlySpentCents, cents);
      await HomeWidget.saveWidgetData<String>(
        keyUpdatedAt,
        DateTime.now().toIso8601String(),
      );

      await _refreshAll();
    } catch (_) {}
  }

  static Future<void> clearWidgetData() => _serialize(() async {
    _lastRefreshedProfile = null;
    try {
      await HomeWidget.saveWidgetData<String>(keyUserId, '');
      await HomeWidget.saveWidgetData<String>(keySnapshot, '');
      await HomeWidget.saveWidgetData<String>(keyStatus, 'logged_out');
      await HomeWidget.saveWidgetData<String>(keyAppearance, '');
      await HomeWidget.saveWidgetData<String>(
        keyMonthlySpent,
        'Abra o PassFin',
      );
      await HomeWidget.saveWidgetData<int>(keyMonthlySpentCents, 0);
      await HomeWidget.saveWidgetData<String>(
        keyUpdatedAt,
        DateTime.now().toIso8601String(),
      );

      await _refreshAll();
    } catch (_) {}
  });
}
