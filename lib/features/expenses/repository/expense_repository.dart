import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/models/expense_model.dart';

class ExpenseStreamSnapshot {
  final List<Expense> expenses;
  final bool isFromCache;
  final bool hasPendingWrites;

  const ExpenseStreamSnapshot({
    required this.expenses,
    required this.isFromCache,
    required this.hasPendingWrites,
  });
}

class ExpenseRepository {
  final FirebaseFirestore? _customFirestore;

  ExpenseRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

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
    if (expense.id != null && expense.id!.isNotEmpty) {
      await _getExpensesCollection(userId).doc(expense.id).set(expense);
    } else {
      await _getExpensesCollection(userId).add(expense);
    }
  }

  Future<void> restoreExpense(String userId, Expense expense) async {
    if (expense.id != null) {
      await _getExpensesCollection(userId).doc(expense.id).set(expense);
    } else {
      await addExpense(userId, expense);
    }
  }

  Future<void> addExpensesBatch(String userId, List<Expense> expenses) async {
    final batch = _firestore.batch();
    final collection = _getExpensesCollection(userId);
    for (var expense in expenses) {
      if (expense.id != null && expense.id!.isNotEmpty) {
        batch.set(collection.doc(expense.id), expense);
      } else {
        batch.set(collection.doc(), expense);
      }
    }
    await batch.commit();
  }

  Stream<List<Expense>> getExpensesStreamForUser(String userId) {
    final querySnapshot = _getExpensesCollection(
      userId,
    ).orderBy('date', descending: true).snapshots();

    return querySnapshot.map(
      (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
    );
  }

  Stream<ExpenseStreamSnapshot> getExpensesWithMetadataStream(String userId) {
    return _getExpensesCollection(userId)
        .orderBy('date', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => ExpenseStreamSnapshot(
            expenses: snapshot.docs.map((doc) => doc.data()).toList(),
            isFromCache: snapshot.metadata.isFromCache,
            hasPendingWrites: snapshot.metadata.hasPendingWrites,
          ),
        );
  }

  Future<List<Expense>> getExpensesForUser(String userId) async {
    final querySnapshot = await _getExpensesCollection(
      userId,
    ).orderBy('date', descending: true).get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateExpense(String userId, Expense expense) async {
    await _getExpensesCollection(
      userId,
    ).doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _getExpensesCollection(userId).doc(expenseId).delete();
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(),
);
