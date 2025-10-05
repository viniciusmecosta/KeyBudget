import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';

class RecurringExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<RecurringExpense> _getRecurringExpensesCollection(
      String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurring_expenses')
        .withConverter<RecurringExpense>(
          fromFirestore: (snapshots, _) =>
              RecurringExpense.fromMap(snapshots.data()!, snapshots.id),
          toFirestore: (expense, _) => expense.toMap(),
        );
  }

  Future<void> addRecurringExpense(
      String userId, RecurringExpense expense) async {
    await _getRecurringExpensesCollection(userId).add(expense);
  }

  Stream<List<RecurringExpense>> getRecurringExpensesStream(String userId) {
    return _getRecurringExpensesCollection(userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> updateRecurringExpense(
      String userId, RecurringExpense expense) async {
    await _getRecurringExpensesCollection(userId)
        .doc(expense.id)
        .update(expense.toMap());
  }

  Future<void> deleteRecurringExpense(String userId, String expenseId) async {
    await _getRecurringExpensesCollection(userId).doc(expenseId).delete();
  }
}
