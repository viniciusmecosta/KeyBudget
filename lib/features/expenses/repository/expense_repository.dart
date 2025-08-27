import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/models/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Expense> _getExpensesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .withConverter<Expense>(
          fromFirestore: (snapshots, _) =>
              Expense.fromMap(snapshots.data()!, snapshots.id),
          toFirestore: (expense, _) => expense.toMap(),
        );
  }

  Future<void> addExpense(String userId, Expense expense) async {
    await _getExpensesCollection(userId).add(expense);
  }

  Stream<List<Expense>> getExpensesStreamForUser(String userId) {
    final querySnapshot = _getExpensesCollection(userId)
        .orderBy('date', descending: true)
        .snapshots();

    return querySnapshot
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Expense>> getExpensesForUser(String userId) async {
    final querySnapshot = await _getExpensesCollection(userId)
        .orderBy('date', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateExpense(String userId, Expense expense) async {
    await _getExpensesCollection(userId)
        .doc(expense.id)
        .update(expense.toMap());
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _getExpensesCollection(userId).doc(expenseId).delete();
  }
}
