import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  final CsvService _csvService = CsvService();

  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchExpenses(int userId) async {
    _setLoading(true);
    _expenses = await _repository.getExpensesForUser(userId);
    _setLoading(false);
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.addExpense(expense);
    await fetchExpenses(expense.userId);
  }

  Future<void> updateExpense(Expense expense) async {
    await _repository.updateExpense(expense);
    await fetchExpenses(expense.userId);
  }

  Future<void> deleteExpense(int id, int userId) async {
    await _repository.deleteExpense(id);
    await fetchExpenses(userId);
  }

  Future<bool> exportExpensesToCsv(DateTime? start, DateTime? end) async {
    List<Expense> expensesToExport = _expenses;
    if (start != null && end != null) {
      expensesToExport = _expenses
          .where((exp) =>
              exp.date.isAfter(start.subtract(const Duration(days: 1))) &&
              exp.date.isBefore(end.add(const Duration(days: 1))))
          .toList();
    }
    return await _csvService.exportExpenses(expensesToExport);
  }

  Future<int> importExpensesFromCsv(int userId) async {
    final data = await _csvService.importCsv();
    if (data == null) return 0;

    int count = 0;
    for (var row in data) {
      final newExpense = Expense(
        userId: userId,
        date:
            DateTime.tryParse(row['date']?.toString() ?? '') ?? DateTime.now(),
        amount: double.tryParse(row['amount']?.toString() ?? '0.0') ?? 0.0,
        category: row['category']?.toString(),
        motivation: row['motivation']?.toString(),
      );
      await _repository.addExpense(newExpense);
      count++;
    }
    await fetchExpenses(userId);
    return count;
  }
}
