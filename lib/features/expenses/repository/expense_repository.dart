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

class ExpensePage {
  final List<Expense> expenses;
  final DocumentSnapshot<Expense>? nextCursor;

  const ExpensePage({required this.expenses, required this.nextCursor});

  bool get hasMore => nextCursor != null;
}

class ExpensePeriodTotals {
  final int expensesMinor;
  final int incomesMinor;

  const ExpensePeriodTotals({
    required this.expensesMinor,
    required this.incomesMinor,
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

  Stream<ExpenseStreamSnapshot> watchPeriod(
    String userId,
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    if (!startInclusive.isBefore(endExclusive)) {
      throw ArgumentError('O período deve ter início anterior ao fim.');
    }
    return getExpensesWithMetadataStream(userId).map(
      (snapshot) => ExpenseStreamSnapshot(
        expenses: snapshot.expenses
            .where(
              (expense) =>
                  !expense.date.isBefore(startInclusive) &&
                  expense.date.isBefore(endExclusive),
            )
            .toList(),
        isFromCache: snapshot.isFromCache,
        hasPendingWrites: snapshot.hasPendingWrites,
      ),
    );
  }

  Future<ExpensePage> getHistoryPage(
    String userId, {
    DateTime? startInclusive,
    DateTime? endExclusive,
    DocumentSnapshot<Expense>? after,
    int pageSize = 50,
  }) async {
    if (pageSize < 1 || pageSize > 200) {
      throw ArgumentError.value(pageSize, 'pageSize');
    }
    if ((startInclusive == null) != (endExclusive == null) ||
        (startInclusive != null && !startInclusive.isBefore(endExclusive!))) {
      throw ArgumentError('Informe um período válido.');
    }
    final ordered = _getExpensesCollection(
      userId,
    ).orderBy('date', descending: true);
    final visible = <Expense>[];
    DocumentSnapshot<Expense>? lastIncluded;
    DocumentSnapshot<Expense>? scanCursor = after;
    while (true) {
      final query = scanCursor == null
          ? ordered
          : ordered.startAfterDocument(scanCursor);
      final snapshot = await query.limit(200).get();
      if (snapshot.docs.isEmpty) {
        return ExpensePage(expenses: visible, nextCursor: null);
      }
      for (final doc in snapshot.docs) {
        final expense = doc.data();
        scanCursor = doc;
        if (startInclusive != null &&
            (expense.date.isBefore(startInclusive) ||
                !expense.date.isBefore(endExclusive!))) {
          continue;
        }
        if (visible.length == pageSize) {
          return ExpensePage(expenses: visible, nextCursor: lastIncluded);
        }
        visible.add(expense);
        lastIncluded = doc;
      }
      if (snapshot.docs.length < 200) {
        return ExpensePage(expenses: visible, nextCursor: null);
      }
    }
  }

  Future<ExpensePeriodTotals> getPeriodTotals(
    String userId,
    DateTime startInclusive,
    DateTime endExclusive,
  ) async {
    var expenseMinor = 0;
    var incomeMinor = 0;
    DocumentSnapshot<Expense>? cursor;
    do {
      final page = await getHistoryPage(
        userId,
        startInclusive: startInclusive,
        endExclusive: endExclusive,
        after: cursor,
        pageSize: 200,
      );
      for (final expense in page.expenses) {
        if (expense.isIncome == true) {
          incomeMinor += expense.money.amountMinor;
        } else {
          expenseMinor += expense.money.amountMinor;
        }
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    return ExpensePeriodTotals(
      expensesMinor: expenseMinor,
      incomesMinor: incomeMinor,
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
