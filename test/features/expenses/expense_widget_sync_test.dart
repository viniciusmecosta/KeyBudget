import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/models/expense_model.dart';
import 'package:passfin/core/models/recurring_expense_model.dart';
import 'package:passfin/core/services/home_widget_snapshot.dart';
import 'package:passfin/core/time/app_clock.dart';
import 'package:passfin/features/expenses/repository/expense_repository.dart';
import 'package:passfin/features/expenses/repository/recurring_expense_repository.dart';
import 'package:passfin/features/expenses/viewmodel/expense_viewmodel.dart';

class _Expenses extends ExpenseRepository {
  final streams = <String, StreamController<ExpenseStreamSnapshot>>{};
  @override
  Stream<ExpenseStreamSnapshot> getExpensesWithMetadataStream(String userId) =>
      streams.putIfAbsent(userId, StreamController.new).stream;
}

class _Recurring extends RecurringExpenseRepository {
  @override
  Stream<List<RecurringExpense>> getRecurringExpensesStream(String userId) =>
      const Stream.empty();
}

void main() {
  test(
    'syncs widgets without a dashboard, preserves cache on failures, and isolates accounts',
    () async {
      final repository = _Expenses();
      final written = <HomeWidgetSnapshot>[];
      final vm = ExpenseViewModel(
        repository: repository,
        recurringRepository: _Recurring(),
        clock: TestAppClock(DateTime(2026, 12, 31)),
        widgetSnapshotWriter: (snapshot) async => written.add(snapshot),
      );
      Future<void> emit(
        String uid,
        List<Expense> entries, {
        bool cache = false,
      }) async {
        repository.streams[uid]!.add(
          ExpenseStreamSnapshot(
            expenses: entries,
            isFromCache: cache,
            hasPendingWrites: false,
          ),
        );
        await Future<void>.delayed(Duration.zero);
      }

      vm.listenToExpenses('first');
      await emit('first', [], cache: true);
      expect(written, isEmpty);
      await emit('first', [
        Expense(amount: 12.34, date: DateTime(2026, 12, 31)),
      ]);
      expect(written.single.spentCents, 1234);
      vm.setSearchQuery('no matches');
      expect(written, hasLength(1));
      vm.setEnableIncomes(true);
      expect(written.last.showIncome, isTrue);
      await emit('first', [], cache: true);
      vm.setEnableIncomes(false);
      expect(written.last.spentCents, 1234);
      repository.streams['first']!.addError(StateError('offline'));
      await Future<void>.delayed(Duration.zero);
      expect(written.last.spentCents, 1234);
      vm.listenToExpenses('second');
      await emit('second', []);
      expect(written.last.userId, 'second');
      expect(written.last.spentCents, 0);
      expect(written.last.dailyTotals, isEmpty);
      vm.clearData();
      final count = written.length;
      vm.setEnableIncomes(true);
      expect(written, hasLength(count));
      vm.dispose();
      for (final stream in repository.streams.values) {
        await stream.close();
      }
    },
  );
}
