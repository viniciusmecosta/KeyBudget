import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/features/expenses/application/recurrence_generation_coordinator.dart';
import 'package:key_budget/features/expenses/application/recurrence_service.dart';

class _PendingRecurrenceService extends Fake implements RecurrenceService {
  final firstResult = Completer<OperationResult<List<Expense>>>();
  int calls = 0;

  @override
  Future<OperationResult<List<Expense>>> generatePendingOccurrences(
    String userId, {
    List<RecurringExpense>? rulesToProcess,
    int maxOccurrencesPerRule = 60,
  }) {
    calls++;
    if (calls == 1) return firstResult.future;
    return Future.value(OperationResult.completed(data: <Expense>[]));
  }
}

void main() {
  test(
    'concurrent refreshes generate once and reconcile only after success',
    () async {
      final service = _PendingRecurrenceService();
      var reconciliations = 0;
      final coordinator = RecurrenceGenerationCoordinator(
        recurrenceService: service,
        reconcileNotifications: (_, _) async => reconciliations++,
      );
      final first = coordinator.synchronize('user', []);
      await coordinator.synchronize('user', []);
      expect(service.calls, 1);
      expect(reconciliations, 0);

      service.firstResult.complete(
        OperationResult.completed(data: <Expense>[]),
      );
      await first;
      expect(reconciliations, 1);
      await coordinator.synchronize('user', []);
      expect(service.calls, 2);
      expect(reconciliations, 2);
    },
  );
}
