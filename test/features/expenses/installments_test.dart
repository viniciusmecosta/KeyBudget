import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/features/expenses/domain/installment_calculator.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class FakeExpenseRepository extends ExpenseRepository {
  final List<Expense> savedExpenses = [];

  @override
  Future<void> addExpensesBatch(String userId, List<Expense> expenses) async {
    for (final exp in expenses) {
      final existingIndex = savedExpenses.indexWhere((e) => e.id == exp.id);
      if (existingIndex >= 0) {
        savedExpenses[existingIndex] = exp;
      } else {
        savedExpenses.add(exp);
      }
    }
  }

  @override
  Future<void> addExpense(String userId, Expense expense) async {
    savedExpenses.add(expense);
  }
}

void main() {
  group('InstallmentCalculator', () {
    test('100,00 em 3 parcelas resulta em 3334 + 3333 + 3333 com soma exata de 10000', () {
      final base = Expense.withMoney(
        money: Money.fromCents(10000),
        date: DateTime(2026, 1, 15),
        motivation: 'Curso online',
        categoryId: 'cat_edu',
      );

      final result = InstallmentCalculator.calculate(
        baseExpense: base,
        count: 3,
        startNextMonth: false,
      );

      expect(result.expenses.length, 3);
      expect(result.expenses[0].amountMinor, 3334);
      expect(result.expenses[1].amountMinor, 3333);
      expect(result.expenses[2].amountMinor, 3333);

      expect(result.sumOfCents, 10000);
      expect(result.expenses[0].motivation, 'Curso online (1/3)');
      expect(result.expenses[1].motivation, 'Curso online (2/3)');
      expect(result.expenses[2].motivation, 'Curso online (3/3)');
      expect(result.expenses[0].currentInstallment, 1);
      expect(result.expenses[0].totalInstallments, 3);
    });

    test('0,01 em 2 parcelas dispara validação de zero centavos e nada é gerado', () {
      final base = Expense.withMoney(
        money: Money.fromCents(1),
        date: DateTime(2026, 1, 15),
      );

      expect(
        () => InstallmentCalculator.calculate(
          baseExpense: base,
          count: 2,
          startNextMonth: false,
        ),
        throwsArgumentError,
      );
    });

    test('10,00 em 1 parcela gera 1000 centavos sem perda', () {
      final base = Expense.withMoney(
        money: Money.fromCents(1000),
        date: DateTime(2026, 1, 15),
      );

      final result = InstallmentCalculator.calculate(
        baseExpense: base,
        count: 1,
        startNextMonth: false,
      );

      expect(result.expenses.length, 1);
      expect(result.expenses[0].amountMinor, 1000);
      expect(result.sumOfCents, 1000);
    });

    test('Manter âncora de dia original: Janeiro 31 -> Fevereiro 28 -> Março 31', () {
      final base = Expense.withMoney(
        money: Money.fromCents(9000),
        date: DateTime(2025, 1, 31, 14, 30),
      );

      final result = InstallmentCalculator.calculate(
        baseExpense: base,
        count: 3,
        startNextMonth: false,
      );

      expect(result.expenses[0].date, DateTime(2025, 1, 31, 14, 30));
      expect(result.expenses[1].date, DateTime(2025, 2, 28, 14, 30));
      expect(result.expenses[2].date, DateTime(2025, 3, 31, 14, 30));
    });

    test('startNextMonth avança primeiro mês corretamente', () {
      final base = Expense.withMoney(
        money: Money.fromCents(6000),
        date: DateTime(2026, 1, 15),
      );

      final result = InstallmentCalculator.calculate(
        baseExpense: base,
        count: 2,
        startNextMonth: true,
      );

      expect(result.expenses[0].date, DateTime(2026, 2, 15));
      expect(result.expenses[1].date, DateTime(2026, 3, 15));
    });

    test('Receita com isIncome == true é estritamente proibida de parcelar', () {
      final income = Expense.withMoney(
        money: Money.fromCents(10000),
        date: DateTime(2026, 1, 15),
        isIncome: true,
      );

      expect(
        () => InstallmentCalculator.calculate(
          baseExpense: income,
          count: 3,
          startNextMonth: false,
        ),
        throwsArgumentError,
      );
    });

    test('Idempotência de retry: mesmo operationId gera os mesmos IDs de grupo e itens', () {
      final base = Expense.withMoney(
        money: Money.fromCents(10000),
        date: DateTime(2026, 1, 15),
      );

      const opId = 'op_retry_test_123';
      final run1 = InstallmentCalculator.calculate(
        baseExpense: base,
        count: 3,
        startNextMonth: false,
        operationId: opId,
      );

      final run2 = InstallmentCalculator.calculate(
        baseExpense: base,
        count: 3,
        startNextMonth: false,
        operationId: opId,
      );

      expect(run1.groupId, opId);
      expect(run2.groupId, opId);
      for (int i = 0; i < 3; i++) {
        expect(run1.expenses[i].id, run2.expenses[i].id);
        expect(run1.expenses[i].amountMinor, run2.expenses[i].amountMinor);
      }
    });

    test('ExpenseViewModel.addInstallmentExpenses grava lote com sucesso e é idempotente no repositório', () async {
      final fakeRepo = FakeExpenseRepository();
      final vm = ExpenseViewModel(repository: fakeRepo);

      final base = Expense.withMoney(
        money: Money.fromCents(10000),
        date: DateTime(2026, 1, 15),
        motivation: 'Compra parcelada',
      );

      final result1 = await vm.addInstallmentExpenses(
        'user_123',
        base,
        3,
        false,
        operationId: 'op_idempotent_grp',
      );

      expect(result1.status, OperationStatus.completed);
      expect(result1.totalCount, 3);
      expect(fakeRepo.savedExpenses.length, 3);

      final result2 = await vm.addInstallmentExpenses(
        'user_123',
        base,
        3,
        false,
        operationId: 'op_idempotent_grp',
      );

      expect(result2.status, OperationStatus.completed);

      expect(fakeRepo.savedExpenses.length, 3);
    });
  });
}
