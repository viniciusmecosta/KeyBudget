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
  }) {
    final spent = expenses
        .where((expense) {
          return expense.categoryId == categoryId &&
              expense.isIncome != true &&
              expense.date.year == now.year &&
              expense.date.month == now.month &&
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
