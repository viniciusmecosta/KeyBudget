import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

final expensesForMonthProvider =
    StreamProvider.family<List<Expense>, ({String userId, DateTime month})>((
      ref,
      scope,
    ) {
      final start = DateTime(scope.month.year, scope.month.month);
      final end = DateTime(scope.month.year, scope.month.month + 1);
      return ref
          .read(expenseRepositoryProvider)
          .watchPeriod(scope.userId, start, end)
          .map((snapshot) => snapshot.expenses);
    });
