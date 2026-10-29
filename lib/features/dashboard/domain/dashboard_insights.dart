import 'package:passfin/core/models/expense_model.dart';

/// All aggregation stays in cents. Future entries never inflate realized data.
class DashboardInsights {
  final List<int> accumulated;
  final List<int> monthPeriods;
  final List<int> upcoming;
  final List<int> daily;
  final List<int> weekdays;
  final DateTime today;

  const DashboardInsights({
    required this.accumulated,
    required this.monthPeriods,
    required this.upcoming,
    this.daily = const [],
    this.weekdays = const [],
    required this.today,
  });

  factory DashboardInsights.fromExpenses(List<Expense> expenses, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final daily = List<int>.filled(now.day, 0);
    final periods = List<int>.filled((now.day / 7).ceil(), 0);
    final weekdays = List<int>.filled(7, 0);
    final upcoming = List<int>.filled(7, 0);
    for (final expense in expenses) {
      if (expense.isIncome == true) continue;
      final date = expense.date;
      final day = DateTime(date.year, date.month, date.day);
      if (date.year == now.year &&
          date.month == now.month &&
          !day.isAfter(today)) {
        daily[date.day - 1] += expense.money.amountMinor;
        weekdays[day.weekday - 1] += expense.money.amountMinor;
        periods[(date.day - 1) ~/ 7] += expense.money.amountMinor;
      }
      // UTC date ordinals avoid daylight-saving shifts in calendar distances.
      final distance = DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
      if (distance >= 1 && distance <= 7) {
        upcoming[distance - 1] += expense.money.amountMinor;
      }
    }
    final accumulated = <int>[0];
    for (final amount in daily) {
      accumulated.add(accumulated.last + amount);
    }
    return DashboardInsights(
      accumulated: accumulated,
      daily: daily,
      weekdays: weekdays,
      monthPeriods: periods,
      upcoming: upcoming,
      today: today,
    );
  }
}
