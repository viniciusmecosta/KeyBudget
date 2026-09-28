import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/features/category/repository/category_budget_repository.dart';

void main() {
  test(
    'monthly category budget uses exact cents and excludes future expenses',
    () {
      final now = DateTime(2026, 10, 15, 12);
      Expense expense(
        int cents,
        DateTime date, {
        String? categoryId,
        bool? isIncome,
      }) {
        return Expense.withMoney(
          money: Money.fromCents(cents),
          date: date,
          categoryId: categoryId ?? 'food',
          isIncome: isIncome,
        );
      }

      final progress = CategoryBudgetRepository.progressFor(
        categoryId: 'food',
        limitMinor: 10000,
        now: now,
        expenses: [
          expense(3333, DateTime(2026, 10, 1)),
          expense(3333, DateTime(2026, 10, 15, 10)),
          expense(5000, DateTime(2026, 10, 20)),
          expense(1000, DateTime(2026, 9, 30)),
          expense(2000, DateTime(2026, 10, 2), categoryId: 'travel'),
          expense(5000, DateTime(2026, 10, 3), isIncome: true),
        ],
      );

      expect(progress.spentMinor, 6666);
      expect(progress.remainingMinor, 3334);
      expect(progress.isExceeded, isFalse);
    },
  );
}
