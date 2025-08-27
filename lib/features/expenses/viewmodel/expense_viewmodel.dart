import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/data_import_service.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  final CsvService _csvService = CsvService();
  final DataImportService _dataImportService = DataImportService();

  List<Expense> _allExpenses = [];
  bool _isLoading = false;
  List<String> _selectedCategoryIds = [];

  List<Expense> get allExpenses => _allExpenses;

  bool get isLoading => _isLoading;

  List<String> get selectedCategoryIds => _selectedCategoryIds;

  List<Expense> get filteredExpenses {
    List<Expense> filtered = List.from(_allExpenses);

    if (_selectedCategoryIds.isNotEmpty) {
      filtered = filtered
          .where((exp) =>
              exp.categoryId != null &&
              _selectedCategoryIds.contains(exp.categoryId))
          .toList();
    }

    return filtered;
  }

  void setCategoryFilter(List<String> categoryIds) {
    _selectedCategoryIds = categoryIds;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategoryIds = [];
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
        // TODO: Handle category import properly, maybe by name
        categoryId: null,
        motivation: row['motivation']?.toString(),
        location: row['location']?.toString(),
      );
      await _repository.addExpense(userId, newExpense);
      count++;
    }
    await fetchExpenses(userId);
    return count;
  }

  Future<int> importAllExpensesFromJson(String userId) async {
    _setLoading(true);
    final count = await _dataImportService.importExpensesFromJsons(userId);
    await fetchExpenses(userId);
    _setLoading(false);
    return count;
  }

  List<String> getUniqueLocationsForCategory(String? categoryId) {
    if (categoryId == null) return [];
    final locations = _allExpenses
        .where((exp) =>
            exp.categoryId == categoryId &&
            exp.location != null &&
            exp.location!.isNotEmpty)
        .map((exp) => exp.location!)
        .toList();

    if (locations.isEmpty) return [];

    final frequencyMap = <String, int>{};
    for (var location in locations) {
      frequencyMap[location] = (frequencyMap[location] ?? 0) + 1;
    }

    final sortedLocations = frequencyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedLocations.map((e) => e.key).take(3).toList();
  }

  List<String> getUniqueMotivationsForCategory(String? categoryId) {
    if (categoryId == null) return [];
    final motivations = _allExpenses
        .where((exp) =>
            exp.categoryId == categoryId &&
            exp.motivation != null &&
            exp.motivation!.isNotEmpty)
        .map((exp) => exp.motivation!)
        .toList();

    if (motivations.isEmpty) return [];

    final frequencyMap = <String, int>{};
    for (var motivation in motivations) {
      frequencyMap[motivation] = (frequencyMap[motivation] ?? 0) + 1;
    }

    final sortedMotivations = frequencyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMotivations.map((e) => e.key).take(3).toList();
  }

  void clearData() {
    _allExpenses = [];
    _selectedCategoryIds = [];
    notifyListeners();
  }
}
