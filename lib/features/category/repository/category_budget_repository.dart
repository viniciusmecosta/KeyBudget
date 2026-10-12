import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/models/expense_model.dart';

class CategoryBudgetProgress {
  final int limitMinor;
  final int spentMinor;

  const CategoryBudgetProgress({
    required this.limitMinor,
    required this.spentMinor,
  });

  int get remainingMinor => limitMinor - spentMinor;
  double get fraction => limitMinor <= 0 ? 0 : spentMinor / limitMinor;
  bool get isExceeded => spentMinor > limitMinor;
}

class CategoryBudgetRepository {
  final FirebaseFirestore? _customFirestore;

  CategoryBudgetRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  Stream<Map<String, int>> watchBudgets(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((
      snapshot,
    ) {
      final raw = snapshot.data()?['category_budgets'];
      if (raw is! Map) return <String, int>{};
      return {
        for (final entry in raw.entries)
          if (entry.key is String && entry.value is int && entry.value > 0)
            entry.key as String: entry.value as int,
      };
    });
  }

  static String monthKey(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

  static Map<String, int> resolveMonthly(
    Map<String, int> legacy,
    Map<String, int> overrides,
  ) {
    final effective = Map<String, int>.from(legacy);
    for (final entry in overrides.entries) {
      if (entry.value <= 0) {
        effective.remove(entry.key);
      } else {
        effective[entry.key] = entry.value;
      }
    }
    return effective;
  }

  Stream<Map<String, int>> watchBudgetsForMonth(String userId, DateTime month) {
    final monthDocument = _firestore
        .collection('users')
        .doc(userId)
        .collection('category_budget_months')
        .doc(monthKey(month));
    late StreamController<Map<String, int>> controller;
    StreamSubscription<Map<String, int>>? legacySubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    monthSubscription;
    Map<String, int>? legacy;
    Map<String, int>? overrides;

    void emit() {
      if (legacy != null && overrides != null && !controller.isClosed) {
        controller.add(resolveMonthly(legacy!, overrides!));
      }
    }

    controller = StreamController<Map<String, int>>(
      onListen: () {
        legacySubscription = watchBudgets(userId).listen((value) {
          legacy = value;
          emit();
        }, onError: controller.addError);
        monthSubscription = monthDocument.snapshots().listen((snapshot) {
          final raw = snapshot.data()?['limits'];
          overrides = {
            if (raw is Map)
              for (final entry in raw.entries)
                if (entry.key is String && entry.value is int)
                  entry.key as String: entry.value as int,
          };
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await legacySubscription?.cancel();
        await monthSubscription?.cancel();
      },
    );
    return controller.stream;
  }

  Future<void> setMonthlyBudget(
    String userId,
    DateTime month,
    String categoryId,
    int? limitMinor,
  ) async {
    if (categoryId.isEmpty || (limitMinor != null && limitMinor <= 0)) {
      throw ArgumentError('Limite de orçamento inválido.');
    }
    final document = _firestore
        .collection('users')
        .doc(userId)
        .collection('category_budget_months')
        .doc(monthKey(month));
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      final raw = snapshot.data()?['limits'];
      final limits = <String, dynamic>{
        if (raw is Map) ...raw.cast<String, dynamic>(),
      };
      limits[categoryId] = limitMinor ?? 0;
      transaction.set(document, {'limits': limits}, SetOptions(merge: true));
    });
  }

  Future<void> setBudget(
    String userId,
    String categoryId,
    int? limitMinor,
  ) async {
    if (categoryId.isEmpty || (limitMinor != null && limitMinor <= 0)) {
      throw ArgumentError('Limite de orçamento inválido.');
    }
    final profile = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(profile);
      if (!snapshot.exists) throw StateError('Perfil não encontrado.');
      final raw = snapshot.data()?['category_budgets'];
      final budgets = <String, dynamic>{
        if (raw is Map) ...raw.cast<String, dynamic>(),
      };
      if (limitMinor == null) {
        budgets.remove(categoryId);
      } else {
        budgets[categoryId] = limitMinor;
      }
      transaction.update(profile, {'category_budgets': budgets});
    });
  }

  static CategoryBudgetProgress progressFor({
    required String categoryId,
    required int limitMinor,
    required List<Expense> expenses,
    required DateTime now,
    DateTime? month,
  }) {
    final period = month ?? now;
    final spent = expenses
        .where((expense) {
          return expense.categoryId == categoryId &&
              expense.isIncome != true &&
              expense.date.year == period.year &&
              expense.date.month == period.month &&
              !expense.date.isAfter(now);
        })
        .fold<int>(0, (total, expense) => total + expense.money.amountMinor);
    return CategoryBudgetProgress(limitMinor: limitMinor, spentMinor: spent);
  }
}

final categoryBudgetRepositoryProvider = Provider<CategoryBudgetRepository>(
  (ref) => CategoryBudgetRepository(),
);

final categoryBudgetsProvider = StreamProvider.family<Map<String, int>, String>(
  (ref, userId) =>
      ref.read(categoryBudgetRepositoryProvider).watchBudgets(userId),
);

final categoryBudgetsForMonthProvider =
    StreamProvider.family<Map<String, int>, ({String userId, DateTime month})>(
      (ref, scope) => ref
          .read(categoryBudgetRepositoryProvider)
          .watchBudgetsForMonth(scope.userId, scope.month),
    );
