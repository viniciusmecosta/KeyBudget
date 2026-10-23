import 'package:intl/intl.dart';
import 'package:key_budget/core/models/expense_model.dart';

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
  });

  final String userId;
  final DateTime date;
  final int spentCents;
  final int incomeCents;
  final int upcomingCents;
  final int upcomingCount;
  final bool showIncome;

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
    for (final expense in expenses) {
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
    );
  }

  Map<String, Object> toMap() {
    final currency = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return {
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
