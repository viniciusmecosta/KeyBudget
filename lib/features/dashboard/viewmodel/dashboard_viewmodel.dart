import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/models/expense_category.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final CredentialRepository _credentialRepository = CredentialRepository();

  bool _isLoading = false;
  int _credentialCount = 0;
  List<Expense> _allExpenses = [];
  Map<String, double> _expensesByCategoryForMonth = {};
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool get isLoading => _isLoading;
  int get credentialCount => _credentialCount;
  Map<String, double> get expensesByCategoryForMonth =>
      _expensesByCategoryForMonth;
  DateTime get selectedMonth => _selectedMonth;

  double get totalAmountForMonth {
    final filteredExpenses = _allExpenses.where((exp) {
      return exp.date.year == _selectedMonth.year &&
          exp.date.month == _selectedMonth.month;
    }).toList();
    return filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> get monthlyExpenseTotals {
    Map<String, double> totals = {};
    for (var expense in _allExpenses) {
      String monthKey =
          '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      totals.update(monthKey, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }
    return totals;
  }

  Map<DateTime, double> get lastSixMonthsExpenseTotals {
    final Map<DateTime, double> totals = {};
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      totals[month] = 0.0;
    }

    for (var expense in _allExpenses) {
      final expenseMonth = DateTime(expense.date.year, expense.date.month, 1);
      if (totals.containsKey(expenseMonth)) {
        totals[expenseMonth] = totals[expenseMonth]! + expense.amount;
      }
    }
    return totals;
  }

  List<Expense> get recentExpenses {
    _allExpenses.sort((a, b) => b.date.compareTo(a.date));
    return _allExpenses.take(5).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> fetchDashboardData(String userId) async {
    _setLoading(true);

    final credentials =
        await _credentialRepository.getCredentialsForUser(userId);
    _credentialCount = credentials.length;

    _allExpenses = await _expenseRepository.getExpensesForUser(userId);
    filterExpensesByMonth(_selectedMonth);

    _setLoading(false);
  }

  void filterExpensesByMonth(DateTime month) {
    _selectedMonth = month;
    final filteredExpenses = _allExpenses.where((exp) {
      return exp.date.year == month.year && exp.date.month == month.month;
    }).toList();

    _expensesByCategoryForMonth = {};
    for (var expense in filteredExpenses) {
      final category = expense.category?.displayName ?? 'Outros';
      _expensesByCategoryForMonth.update(
          category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }
    notifyListeners();
  }

  void clearData() {
    _isLoading = false;
    _credentialCount = 0;
    _allExpenses = [];
    _expensesByCategoryForMonth = {};
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    notifyListeners();
  }
}
