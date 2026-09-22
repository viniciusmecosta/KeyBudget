import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:key_budget/features/expenses/domain/recurrence_occurrence.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/repository/recurrence_occurrence_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';

enum RecurrenceDeleteMode { onlyRule, futureOnly, all }

class RecurringDeleteSnapshot {
  final RecurringExpense rule;
  final List<Expense> deletedExpenses;
  final RecurrenceDeleteMode mode;
  final DateTime deletedAt;

  const RecurringDeleteSnapshot({
    required this.rule,
    required this.deletedExpenses,
    required this.mode,
    required this.deletedAt,
  });
}

class RecurrenceDeletionService {
  final RecurringExpenseRepository recurringRepository;
  final ExpenseRepository expenseRepository;
  final RecurrenceOccurrenceRepository occurrenceRepository;
  final AppClock clock;

  RecurrenceDeletionService({
    required this.recurringRepository,
    required this.expenseRepository,
    required this.occurrenceRepository,
    this.clock = const SystemAppClock(),
  });

  Future<OperationResult<RecurringDeleteSnapshot>> deleteRule({
    required String userId,
    required RecurringExpense rule,
    required RecurrenceDeleteMode mode,
    required List<Expense> allExpenses,
  }) async {
    try {
      final now = clock.now();
      final endOfToday = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
        999,
      );

      final linkedExpenses = allExpenses
          .where((e) => e.recurringExpenseId == rule.id)
          .toList();

      final List<Expense> expensesToDelete;
      switch (mode) {
        case RecurrenceDeleteMode.onlyRule:
          expensesToDelete = [];
          break;
        case RecurrenceDeleteMode.futureOnly:
          expensesToDelete = linkedExpenses
              .where((e) => e.date.isAfter(endOfToday))
              .toList();
          break;
        case RecurrenceDeleteMode.all:
          expensesToDelete = linkedExpenses;
          break;
      }

      final snapshot = RecurringDeleteSnapshot(
        rule: rule,
        deletedExpenses: expensesToDelete,
        mode: mode,
        deletedAt: now,
      );

      for (final exp in expensesToDelete) {
        if (exp.id != null && exp.id!.isNotEmpty) {
          await expenseRepository.deleteExpense(userId, exp.id!);
        }
      }

      if (rule.id != null) {
        await recurringRepository.deleteRecurringExpense(userId, rule.id!);
      }

      return OperationResult.completed(
        data: snapshot,
        count: expensesToDelete.length + 1,
        affectedIds: [
          rule.id ?? '',
          ...expensesToDelete.map((e) => e.id ?? ''),
        ],
      );
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Falha ao excluir regra recorrente: ${e.toString()}',
      );
    }
  }

  Future<OperationResult<void>> undoDelete({
    required String userId,
    required RecurringDeleteSnapshot snapshot,
  }) async {
    try {
      await recurringRepository.restoreRecurringExpense(userId, snapshot.rule);

      for (final exp in snapshot.deletedExpenses) {
        await expenseRepository.restoreExpense(userId, exp);
      }

      return OperationResult.completed(
        count: snapshot.deletedExpenses.length + 1,
      );
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Falha ao desfazer exclusão da regra: ${e.toString()}',
      );
    }
  }

  Future<OperationResult<void>> deleteIndividualOccurrence({
    required String userId,
    required Expense expense,
  }) async {
    try {
      final expenseId = expense.id;
      if (expenseId == null || expenseId.isEmpty) {
        return OperationResult.failed(
          safeError: 'Identificador de despesa inválido para exclusão.',
        );
      }

      if (expense.recurringExpenseId != null &&
          expense.recurringExpenseId!.isNotEmpty) {
        final dateKey =
            expense.scheduledDateKey ??
            RecurrenceOccurrence.formatDateKey(expense.date);
        final occurrenceKey =
            expense.occurrenceKey ??
            RecurrenceOccurrence.generateKey(
              uid: userId,
              recurringExpenseId: expense.recurringExpenseId!,
              scheduledDateKey: dateKey,
            );

        final tombstone = RecurrenceOccurrence(
          occurrenceKey: occurrenceKey,
          recurringExpenseId: expense.recurringExpenseId!,
          scheduledDateKey: dateKey,
          scheduledDateOriginal: expense.date,
          expenseIds: [expenseId],
          state: OccurrenceState.suppressed,
          engineVersion: 1,
        );

        await occurrenceRepository.saveOccurrence(userId, tombstone);
      }

      await expenseRepository.deleteExpense(userId, expenseId);

      return OperationResult.completed(affectedIds: [expenseId], count: 1);
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Falha ao excluir ocorrência: ${e.toString()}',
      );
    }
  }
}
