import 'package:intl/intl.dart';
import 'package:passfin/core/models/expense_model.dart';

/// A single, account-scoped payload avoids mixing values from different updates.
class HomeWidgetSnapshot {
  const HomeWidgetSnapshot({
    required this.userId,
    required this.date,
    required this.spentCents,
    required this.incomeCents,
    required this.upcomingCents,
    required this.upcomingCount,
    required this.showIncome,
    required this.dailyTotals,
  });

  final String userId;
  final DateTime date;
  final int spentCents;
  final int incomeCents;
  final int upcomingCents;
  final int upcomingCount;
  final bool showIncome;

  /// Day -> [expense cents, income cents, expense count]. No descriptions or IDs.
  /// Android can roll dates forward using these already synchronized entries.
  final Map<String, List<int>> dailyTotals;

  factory HomeWidgetSnapshot.fromExpenses({
    required String userId,
    required List<Expense> expenses,
    required DateTime now,
    required bool showIncome,
  }) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final end = DateTime(now.year, now.month, now.day + 8);
    var spent = 0;
    var income = 0;
    var upcoming = 0;
    var count = 0;
    final daily = <String, List<int>>{};
    final dayFormat = DateFormat('yyyy-MM-dd');
    for (final expense in expenses) {
      final totals = daily.putIfAbsent(
        dayFormat.format(expense.date),
        () => [0, 0, 0],
      );
      if (expense.isIncome == true) {
        totals[1] += expense.money.amountMinor;
      } else {
        totals[0] += expense.money.amountMinor;
        totals[2]++;
      }
      if (expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.isBefore(tomorrow)) {
        if (expense.isIncome == true) {
          income += expense.money.amountMinor;
        } else {
          spent += expense.money.amountMinor;
        }
      }
      if (expense.isIncome != true &&
          !expense.date.isBefore(tomorrow) &&
          expense.date.isBefore(end)) {
        upcoming += expense.money.amountMinor;
        count++;
      }
    }
    return HomeWidgetSnapshot(
      userId: userId,
      date: now,
      spentCents: spent,
      incomeCents: income,
      upcomingCents: upcoming,
      upcomingCount: count,
      showIncome: showIncome,
      dailyTotals: daily,
    );
  }

  Map<String, Object> toMap() {
    final currency = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return {
      'version': 2,
      'daily': dailyTotals,
      'uid': userId,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'spent': currency.format(spentCents / 100),
      'income': currency.format(incomeCents / 100),
      'balance': currency.format((incomeCents - spentCents) / 100),
      'upcoming': currency.format(upcomingCents / 100),
      'upcoming_count': upcomingCount,
      'show_income': showIncome,
    };
  }
}
