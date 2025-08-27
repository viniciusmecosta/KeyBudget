import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final CredentialRepository _credentialRepository = CredentialRepository();
  CategoryViewModel categoryViewModel;

  bool _isLoading = false;
  int _credentialCount = 0;
  List<Expense> _allExpenses = [];
  Map<String, double> _expensesByCategoryForMonth = {};
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  DashboardViewModel({required this.categoryViewModel});

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

  double get averageOfPreviousMonths {
    final Map<String, double> monthlyTotals = {};
    for (var expense in _allExpenses) {
      if (expense.date.isBefore(_selectedMonth)) {
        final monthKey = '${expense.date.year}-${expense.date.month}';
        monthlyTotals.update(monthKey, (value) => value + expense.amount,
            ifAbsent: () => expense.amount);
      }
    }
    if (monthlyTotals.isEmpty) return 0.0;
    return monthlyTotals.values.reduce((a, b) => a + b) / monthlyTotals.length;
  }

  double get percentageChangeFromAverage {
    final average = averageOfPreviousMonths;
    if (average == 0) return 0.0;
    return ((totalAmountForMonth - average) / average) * 100;
  }

  List<Expense> get recentExpenses {
    _allExpenses.sort((a, b) => b.date.compareTo(a.date));
    return _allExpenses.take(5).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadDashboardData(String userId) async {
    _setLoading(true);

    await categoryViewModel.fetchCategories(userId);

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
      final category = categoryViewModel.getCategoryById(expense.categoryId);
      final categoryName = category?.name ?? 'Outros';
      _expensesByCategoryForMonth.update(
          categoryName, (value) => value + expense.amount,
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
