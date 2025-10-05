import 'dart:async';

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
  bool _isLoading = true;
  List<String> _selectedCategoryIds = [];
  StreamSubscription? _expensesSubscription;
  bool _isListening = false;

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

  void listenToExpenses(String userId) {
    if (_isListening) {
      return;
    }

    if (!_isLoading) _setLoading(true);
    _expensesSubscription?.cancel();
    _expensesSubscription =
        _repository.getExpensesStreamForUser(userId).listen((expenses) {
      _allExpenses = expenses;
      if (_isLoading) _setLoading(false);
      notifyListeners();
    });
    _isListening = true;
  }

  Future<void> addExpense(String userId, Expense expense) async {
    await _repository.addExpense(userId, expense);
  }

  Future<void> updateExpense(String userId, Expense expense) async {
    await _repository.updateExpense(userId, expense);
  }

  Future<void> deleteExpense(String userId, String expenseId) async {
    await _repository.deleteExpense(userId, expenseId);
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
        categoryId: null,
        motivation: row['motivation']?.toString(),
        location: row['location']?.toString(),
      );
      await _repository.addExpense(userId, newExpense);
      count++;
    }
    return count;
  }

  Future<int> importAllExpensesFromJson(String userId) async {
    _setLoading(true);
    final count = await _dataImportService.importExpensesFromJsons(userId);
    _setLoading(false);
    return count;
  }

  List<String> getUniqueLocationsForCategory(String? categoryId, String query) {
    if (categoryId == null || query.isEmpty) return [];

    final locations = _allExpenses.where((exp) =>
        exp.categoryId == categoryId &&
        exp.location != null &&
        exp.location!.isNotEmpty);

    if (locations.isEmpty) return [];

    final frequencyMap = <String, int>{};
    for (var exp in locations) {
      frequencyMap[exp.location!] = (frequencyMap[exp.location!] ?? 0) + 1;
    }

    final queryLower = query.toLowerCase();
    final filteredLocations = frequencyMap.entries.where((entry) {
      return entry.key
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(queryLower));
    });

    final sortedLocations = filteredLocations.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedLocations.map((e) => e.key).take(3).toList();
  }

  List<String> getUniqueMotivationsForCategory(
      String? categoryId, String query) {
    if (categoryId == null || query.isEmpty) return [];

    final motivations = _allExpenses.where((exp) =>
        exp.categoryId == categoryId &&
        exp.motivation != null &&
        exp.motivation!.isNotEmpty);

    if (motivations.isEmpty) return [];

    final frequencyMap = <String, int>{};
    for (var exp in motivations) {
      frequencyMap[exp.motivation!] = (frequencyMap[exp.motivation!] ?? 0) + 1;
    }

    final queryLower = query.toLowerCase();
    final filteredMotivations = frequencyMap.entries.where((entry) {
      return entry.key
          .toLowerCase()
          .split(' ')
          .any((word) => word.startsWith(queryLower));
    });

    final sortedMotivations = filteredMotivations.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMotivations.map((e) => e.key).take(3).toList();
  }

  void clearData() {
    _expensesSubscription?.cancel();
    _allExpenses = [];
    _selectedCategoryIds = [];
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    super.dispose();
  }
}
