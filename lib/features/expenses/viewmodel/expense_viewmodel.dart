import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_category.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  final CsvService _csvService = CsvService();

  List<Expense> _allExpenses = [];
  bool _isLoading = false;
  List<ExpenseCategory> _selectedCategories = [];

  List<Expense> get allExpenses => _allExpenses;
  bool get isLoading => _isLoading;
  List<ExpenseCategory> get selectedCategories => _selectedCategories;

  List<Expense> get filteredExpenses {
    List<Expense> filtered = List.from(_allExpenses);

    if (_selectedCategories.isNotEmpty) {
      filtered = filtered
          .where((exp) =>
              exp.category != null &&
              _selectedCategories.contains(exp.category))
          .toList();
    }

    return filtered;
  }

  void setCategoryFilter(List<ExpenseCategory> categories) {
    _selectedCategories = categories;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategories = [];
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchExpenses(String userId) async {
    _setLoading(true);
    _allExpenses = await _repository.getExpensesForUser(userId);
    _setLoading(false);
  }

  Future<void> addExpense(String userId, Expense expense) async {
    await _repository.addExpense(userId, expense);
    await fetchExpenses(userId);
  }

  Future<void> updateExpense(String userId, Expense expense) async {
    await _repository.updateExpense(userId, expense);
    await fetchExpenses(userId);
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _repository.deleteExpense(userId, expenseId);
    await fetchExpenses(userId);
  }

  Future<bool> exportExpensesToCsv(DateTime? start, DateTime? end) async {
    List<Expense> expensesToExport = _allExpenses;
    if (start != null && end != null) {
      expensesToExport = _allExpenses
          .where((exp) =>
              exp.date.isAfter(start.subtract(const Duration(days: 1))) &&
              exp.date.isBefore(end.add(const Duration(days: 1))))
          .toList();
    }
    return await _csvService.exportExpenses(expensesToExport);
  }

  Future<int> importExpensesFromCsv(String userId) async {
    final data = await _csvService.importCsv();
    if (data == null) return 0;

    int count = 0;
    for (var row in data) {
      final newExpense = Expense(
        date:
            DateTime.tryParse(row['date']?.toString() ?? '') ?? DateTime.now(),
        amount: double.tryParse(row['amount']?.toString() ?? '0.0') ?? 0.0,
        category: ExpenseCategory.values.firstWhere(
            (e) => e.name == row['category']?.toString(),
            orElse: () => ExpenseCategory.outros),
        motivation: row['motivation']?.toString(),
        location: row['location']?.toString(),
      );
      await _repository.addExpense(userId, newExpense);
      count++;
    }
    await fetchExpenses(userId);
    return count;
  }
}
