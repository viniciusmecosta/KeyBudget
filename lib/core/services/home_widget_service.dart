import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.vinicius.keybudget';
  static const String iOSWidgetName = 'KeyBudgetWidget';
  static const String androidWidgetName = 'KeyBudgetWidgetReceiver';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> updateWidgetData(double monthlySpent) async {
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final formattedAmount = currencyFormatter.format(monthlySpent);

    await HomeWidget.saveWidgetData<String>('monthly_spent', formattedAmount);

    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }
}
