import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/features/category/repository/category_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repository = CategoryRepository();

  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;

  List<ExpenseCategory> get categories => _categories;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchCategories(String userId) async {
    _setLoading(true);
    _categories = await _repository.getCategoriesForUser(userId);
    _categories.sort((a, b) => a.name.compareTo(b.name));
    _setLoading(false);
  }

  Future<void> addCategory(String userId, ExpenseCategory category) async {
    await _repository.addCategory(userId, category);
    await fetchCategories(userId);
  }

  Future<void> updateCategory(String userId, ExpenseCategory category) async {
    await _repository.updateCategory(userId, category);
    await fetchCategories(userId);
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await _repository.deleteCategory(userId, categoryId);
    await fetchCategories(userId);
  }

  ExpenseCategory? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearData() {
    _categories = [];
    notifyListeners();
  }
}
