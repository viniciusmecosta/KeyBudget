import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_model.dart';

void main() {
  group('Expense model and recurring link preservation', () {
    test('copyWith preserves recurringExpenseId and installment details', () {
      final original = Expense(
        id: 'exp_1',
        amount: 150.0,
        date: DateTime(2024, 3, 15),
        categoryId: 'cat_food',
        motivation: 'Lunch',
        location: 'Restaurant',
        installmentGroupId: 'inst_group_1',
        currentInstallment: 2,
        totalInstallments: 5,
        isIncome: false,
        recurringExpenseId: 'rec_rule_42',
      );

      final edited = original.copyWith(
        amount: 175.0,
        date: DateTime(2024, 3, 16),
      );

      expect(edited.id, 'exp_1');
      expect(edited.amount, 175.0);
      expect(edited.date, DateTime(2024, 3, 16));
      expect(edited.categoryId, 'cat_food');
      expect(edited.recurringExpenseId, 'rec_rule_42');
      expect(edited.installmentGroupId, 'inst_group_1');
      expect(edited.currentInstallment, 2);
      expect(edited.totalInstallments, 5);
      expect(edited.isIncome, isFalse);
    });

    test('Expense equality and hashCode account for recurringExpenseId', () {
      final expA = Expense(
        id: 'exp_1',
        amount: 100.0,
        date: DateTime(2024, 1, 1),
        recurringExpenseId: 'rec_1',
      );

      final expB = Expense(
        id: 'exp_1',
        amount: 100.0,
        date: DateTime(2024, 1, 1),
        recurringExpenseId: 'rec_2',
      );

      final expC = Expense(
        id: 'exp_1',
        amount: 100.0,
        date: DateTime(2024, 1, 1),
        recurringExpenseId: 'rec_1',
      );

      expect(expA == expB, isFalse);
      expect(expA == expC, isTrue);
      expect(expA.hashCode, expC.hashCode);
      expect(expA.hashCode == expB.hashCode, isFalse);
    });
  });
}
