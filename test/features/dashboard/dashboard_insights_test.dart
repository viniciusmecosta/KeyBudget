import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/dashboard/domain/dashboard_insights.dart';
import 'package:key_budget/features/dashboard/repository/dashboard_layout_repository.dart';

void main() {
  test('separates realized, future and income with exact cents', () {
    final now = DateTime(2026, 10, 8, 12);
    final data = DashboardInsights.fromExpenses([
      Expense(amount: .1, date: DateTime(2026, 10, 1)),
      Expense(amount: .2, date: DateTime(2026, 10, 7)),
      Expense(amount: 4, date: DateTime(2026, 10, 8, 23)),
      Expense(amount: 90, date: now, isIncome: true),
      Expense(amount: 5, date: DateTime(2026, 10, 9)),
      Expense(amount: 6, date: DateTime(2026, 10, 15)),
      Expense(amount: 100, date: DateTime(2026, 10, 16)),
      Expense(amount: 100, date: DateTime(2026, 9, 30)),
    ], now);
    expect(data.accumulated, [0, 10, 10, 10, 10, 10, 10, 30, 430]);
    expect(data.monthPeriods, [30, 400]);
    expect(data.upcoming, [500, 0, 0, 0, 0, 0, 600]);
  });

  test('future calendar crosses year boundary and handles leap day', () {
    final data = DashboardInsights.fromExpenses([
      Expense(amount: 2, date: DateTime(2027, 1, 1)),
    ], DateTime(2026, 12, 31));
    expect(data.upcoming.first, 200);
    expect(data.monthPeriods.length, 5);
    expect(
      DashboardInsights.fromExpenses(
        [],
        DateTime(2024, 2, 29),
      ).accumulated.length,
      30,
    );
  });

  test('new modules are opt-in and persist in chosen order', () {
    expect(const DashboardLayout().cards, [
      'balance',
      'chart',
      'quick_actions',
      'recent',
    ]);
    final layout = DashboardLayout.fromMap({
      'cards': ['upcoming', 'accumulated', 'periods', 'recent'],
      'integrated_summary': false,
    });
    final restored = DashboardLayout.fromMap(layout.toMap());
    expect(restored.cards, layout.cards);
    expect(restored.integratedSummary, false);
  });
}
