import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/features/category/repository/category_repository.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class _RecoveringExpenseRepository extends ExpenseRepository {
  int calls = 0;

  @override
  Stream<ExpenseStreamSnapshot> getExpensesWithMetadataStream(String userId) {
    calls++;
    if (calls == 1) return Stream.error(StateError('offline'));
    return Stream.value(
      const ExpenseStreamSnapshot(
        expenses: [],
        isFromCache: false,
        hasPendingWrites: false,
      ),
    );
  }
}

class _ControlledExpenseRepository extends ExpenseRepository {
  final controller = StreamController<ExpenseStreamSnapshot>();

  @override
  Stream<ExpenseStreamSnapshot> getExpensesWithMetadataStream(String userId) =>
      controller.stream;
}

class _AccountExpenseRepository extends ExpenseRepository {
  final streams = <String, StreamController<ExpenseStreamSnapshot>>{};

  @override
  Stream<ExpenseStreamSnapshot> getExpensesWithMetadataStream(String userId) =>
      streams.putIfAbsent(userId, StreamController.new).stream;
}

class _EmptyRecurringExpenseRepository extends RecurringExpenseRepository {
  @override
  Stream<List<RecurringExpense>> getRecurringExpensesStream(String userId) =>
      Stream.value([]);
}

class _RecoveringCategoryRepository extends CategoryRepository {
  int calls = 0;

  @override
  Future<List<ExpenseCategory>> getCategoriesForUser(String userId) async {
    calls++;
    if (calls == 1) throw StateError('offline');
    return [];
  }
}

void main() {
  group('loading recovery', () {
    test(
      'account change clears old expenses before the next snapshot',
      () async {
        final repository = _AccountExpenseRepository();
        final viewModel = ExpenseViewModel(
          repository: repository,
          recurringRepository: _EmptyRecurringExpenseRepository(),
        );
        viewModel.listenToExpenses('first');
        repository.streams['first']!.add(
          ExpenseStreamSnapshot(
            expenses: [
              Expense(id: 'private', amount: 42, date: DateTime(2026, 10, 1)),
            ],
            isFromCache: false,
            hasPendingWrites: false,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(viewModel.allExpenses.single.id, 'private');

        viewModel.listenToExpenses('second');
        expect(viewModel.allExpenses, isEmpty);
        expect(viewModel.lastServerConfirmation, isNull);
        repository.streams['first']!.add(
          ExpenseStreamSnapshot(
            expenses: [
              Expense(id: 'stale', amount: 1, date: DateTime(2026, 10, 1)),
            ],
            isFromCache: false,
            hasPendingWrites: false,
          ),
        );
        repository.streams['second']!.add(
          const ExpenseStreamSnapshot(
            expenses: [],
            isFromCache: false,
            hasPendingWrites: false,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(viewModel.allExpenses, isEmpty);
        viewModel.dispose();
        for (final controller in repository.streams.values) {
          await controller.close();
        }
      },
    );

    test('expense stream failure ends loading and can be retried', () async {
      final repository = _RecoveringExpenseRepository();
      final viewModel = ExpenseViewModel(
        repository: repository,
        recurringRepository: _EmptyRecurringExpenseRepository(),
      );

      viewModel.listenToExpenses('user');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.loadErrorMessage, isNotNull);
      expect(viewModel.syncStatus, ExpenseSyncStatus.failed);

      await viewModel.retryListenToExpenses('user');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.loadErrorMessage, isNull);
      expect(viewModel.syncStatus, ExpenseSyncStatus.synced);
      expect(repository.calls, 2);
      viewModel.dispose();
    });

    test(
      'distinguishes cache, pending writes, and server confirmation',
      () async {
        final repository = _ControlledExpenseRepository();
        final viewModel = ExpenseViewModel(
          repository: repository,
          recurringRepository: _EmptyRecurringExpenseRepository(),
        );
        viewModel.listenToExpenses('user');

        void emit({required bool isFromCache, required bool hasPendingWrites}) {
          repository.controller.add(
            ExpenseStreamSnapshot(
              expenses: const [],
              isFromCache: isFromCache,
              hasPendingWrites: hasPendingWrites,
            ),
          );
        }

        emit(isFromCache: true, hasPendingWrites: false);
        await Future<void>.delayed(Duration.zero);
        expect(viewModel.syncStatus, ExpenseSyncStatus.cached);

        emit(isFromCache: true, hasPendingWrites: true);
        await Future<void>.delayed(Duration.zero);
        expect(viewModel.syncStatus, ExpenseSyncStatus.pending);

        emit(isFromCache: false, hasPendingWrites: false);
        await Future<void>.delayed(Duration.zero);
        expect(viewModel.syncStatus, ExpenseSyncStatus.synced);
        expect(viewModel.lastServerConfirmation, isNotNull);

        viewModel.dispose();
        await repository.controller.close();
      },
    );

    test('category fetch failure ends loading and can be retried', () async {
      final repository = _RecoveringCategoryRepository();
      final viewModel = CategoryViewModel(repository: repository);

      await viewModel.fetchCategories('user');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNotNull);

      await viewModel.fetchCategories('user');

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(repository.calls, 2);
      viewModel.dispose();
    });
  });
}
