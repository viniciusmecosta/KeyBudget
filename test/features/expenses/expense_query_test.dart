import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class _PagedRepository extends ExpenseRepository {
  int requests = 0;

  @override
  Future<ExpensePage> getHistoryPage(
    String userId, {
    DateTime? startInclusive,
    DateTime? endExclusive,
    DocumentSnapshot<Expense>? after,
    int pageSize = 50,
  }) async {
    requests++;
    expect(userId, 'user');
    expect(pageSize, 200);
    expect(after, isNull);
    return ExpensePage(
      expenses: [
        Expense(amount: 0.1, date: DateTime(2026, 10, 1)),
        Expense(amount: 0.2, date: DateTime(2026, 10, 2)),
        Expense(
          amount: 3.0,
          amountMinor: 300,
          isIncome: true,
          date: DateTime(2026, 10, 3),
        ),
      ],
      nextCursor: null,
    );
  }
}

void main() {
  test('period totals sum legacy amounts in cents', () async {
    final repository = _PagedRepository();
    final totals = await repository.getPeriodTotals(
      'user',
      DateTime(2026, 10, 1),
      DateTime(2026, 11, 1),
    );
    expect(totals.expensesMinor, 30);
    expect(totals.incomesMinor, 300);
    expect(repository.requests, 1);
  });
}
