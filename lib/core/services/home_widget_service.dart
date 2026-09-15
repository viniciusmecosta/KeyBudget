import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.vinicius.keybudget';
  static const String iOSWidgetName = 'KeyBudgetWidget';
  static const String androidWidgetName = 'KeyBudgetWidgetReceiver';

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
    } catch (_) {

    }
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

  static Future<void> updateWidgetData(
    double monthlySpent, {
    String? uid,
    DateTime? referenceMonth,
    bool? showValuesOverride,
  }) async {
    try {
      final refDate = referenceMonth ?? DateTime.now();
      final monthStr = DateFormat('yyyy-MM').format(refDate);

      final showValues = showValuesOverride ?? await getShowValues();
      final cents = (monthlySpent * 100).round();

      final currencyFormatter = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
        decimalDigits: 2,
      );

      final formattedAmount = showValues
          ? currencyFormatter.format(monthlySpent)
          : 'R\$ •••••';

      await HomeWidget.saveWidgetData<int>(keyWidgetVersion, 1);
      await HomeWidget.saveWidgetData<String>(keyUserId, uid ?? '');
      await HomeWidget.saveWidgetData<String>(keyStatus, uid != null && uid.isNotEmpty ? 'active' : 'logged_out');
      await HomeWidget.saveWidgetData<String>(keyReferenceMonth, monthStr);
      await HomeWidget.saveWidgetData<bool>(keyShowValues, showValues);
      await HomeWidget.saveWidgetData<String>(keyMonthlySpent, formattedAmount);
      await HomeWidget.saveWidgetData<int>(keyMonthlySpentCents, cents);
      await HomeWidget.saveWidgetData<String>(keyUpdatedAt, DateTime.now().toIso8601String());

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (_) {

    }
  }

  static Future<void> clearWidgetData() async {
    try {
      await HomeWidget.saveWidgetData<String>(keyUserId, '');
      await HomeWidget.saveWidgetData<String>(keyStatus, 'logged_out');
      await HomeWidget.saveWidgetData<String>(keyMonthlySpent, 'Abra o KeyBudget');
      await HomeWidget.saveWidgetData<int>(keyMonthlySpentCents, 0);
      await HomeWidget.saveWidgetData<String>(keyUpdatedAt, DateTime.now().toIso8601String());

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (_) {}
  }
}
