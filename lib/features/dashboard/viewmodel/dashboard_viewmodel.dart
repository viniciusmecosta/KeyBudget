import 'package:flutter/material.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class DashboardViewModel extends ChangeNotifier {
  CategoryViewModel categoryViewModel;
  ExpenseViewModel expenseViewModel;
  CredentialViewModel credentialViewModel;

  DashboardViewModel({
    required this.categoryViewModel,
    required this.expenseViewModel,
    required this.credentialViewModel,
  }) {
    _addListeners();
  }

  void _addListeners() {
    categoryViewModel.addListener(notifyListeners);
    expenseViewModel.addListener(notifyListeners);
    credentialViewModel.addListener(notifyListeners);
  }

  void _removeListeners() {
    categoryViewModel.removeListener(notifyListeners);
    expenseViewModel.removeListener(notifyListeners);
    credentialViewModel.removeListener(notifyListeners);
  }

  void updateDependencies({
    required CategoryViewModel categoryViewModel,
    required ExpenseViewModel expenseViewModel,
    required CredentialViewModel credentialViewModel,
  }) {
    if (this.categoryViewModel != categoryViewModel ||
        this.expenseViewModel != expenseViewModel ||
        this.credentialViewModel != credentialViewModel) {
      _removeListeners();
      this.categoryViewModel = categoryViewModel;
      this.expenseViewModel = expenseViewModel;
      this.credentialViewModel = credentialViewModel;
      _addListeners();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  bool get isLoading =>
      categoryViewModel.isLoading ||
      expenseViewModel.isLoading ||
      credentialViewModel.isLoading;

  List<Expense> get allExpenses => expenseViewModel.allExpenses;

  int get credentialCount => credentialViewModel.allCredentials.length;

  double get totalAmountForMonth {
    final now = DateTime.now();
    final filteredExpenses = allExpenses.where((exp) {
      return exp.date.year == now.year && exp.date.month == now.month;
    }).toList();
    return filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get averageOfPreviousMonths {
    final now = DateTime.now();
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    final Map<String, double> monthlyTotals = {};
    for (var expense in allExpenses) {
      if (expense.date.isBefore(firstDayOfCurrentMonth)) {
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
    List<Expense> sortedExpenses = List.from(allExpenses);
    sortedExpenses.sort((a, b) => b.date.compareTo(a.date));
    return sortedExpenses.take(5).toList();
  }

  void clearData() {
    notifyListeners();
  }
}
