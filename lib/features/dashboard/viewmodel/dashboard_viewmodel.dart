import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  bool _isLoading = false;
  Map<String, double> _expenseByCategory = {};

  bool get isLoading => _isLoading;
  Map<String, double> get expenseByCategory => _expenseByCategory;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchDashboardData(int userId) async {
    _setLoading(true);

    final expenses = await _expenseRepository.getExpensesForUser(userId);
    _processExpenses(expenses);

    _setLoading(false);
  }

  void _processExpenses(List<Expense> expenses) {
    _expenseByCategory = {};
    for (var expense in expenses) {
      final category = expense.category ?? 'Outros';
      _expenseByCategory.update(category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }
  }
}
