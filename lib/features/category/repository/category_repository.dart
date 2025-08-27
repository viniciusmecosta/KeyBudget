import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/models/expense_category_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<ExpenseCategory> _getCategoriesCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .withConverter<ExpenseCategory>(
      fromFirestore: (snapshots, _) =>
          ExpenseCategory.fromMap(snapshots.data()!, snapshots.id),
      toFirestore: (category, _) => category.toMap(),
    );
  }

  Future<void> addCategory(String userId, ExpenseCategory category) async {
    await _getCategoriesCollection(userId).add(category);
  }

  Future<List<ExpenseCategory>> getCategoriesForUser(String userId) async {
    final querySnapshot =
    await _getCategoriesCollection(userId).orderBy('name').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateCategory(String userId, ExpenseCategory category) async {
    await _getCategoriesCollection(userId)
        .doc(category.id)
        .update(category.toMap());
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await _getCategoriesCollection(userId).doc(categoryId).delete();
  }
}