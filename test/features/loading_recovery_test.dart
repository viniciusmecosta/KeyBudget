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
  Stream<List<Expense>> getExpensesStreamForUser(String userId) {
    calls++;
    if (calls == 1) return Stream.error(StateError('offline'));
    return Stream.value([]);
  }
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

      await viewModel.retryListenToExpenses('user');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.loadErrorMessage, isNull);
      expect(repository.calls, 2);
      viewModel.dispose();
    });

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
