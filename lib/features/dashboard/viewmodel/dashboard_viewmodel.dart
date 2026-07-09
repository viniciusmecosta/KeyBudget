import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/home_widget_service.dart';
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
    _updateWidget();
  }

  void _addListeners() {
    categoryViewModel.addListener(notifyListeners);
    expenseViewModel.addListener(_onExpensesChanged);
    credentialViewModel.addListener(notifyListeners);
  }

  void _removeListeners() {
    categoryViewModel.removeListener(notifyListeners);
    expenseViewModel.removeListener(_onExpensesChanged);
    credentialViewModel.removeListener(notifyListeners);
  }

  void _onExpensesChanged() {
    notifyListeners();
    _updateWidget();
  }

  Future<void> _updateWidget() async {
    await HomeWidgetService.updateWidgetData(totalAmountForMonth);
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
      _updateWidget();
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
      return exp.date.year == now.year && exp.date.month == now.month && exp.isIncome != true;
    }).toList();
    return filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalIncomeForMonth {
    final now = DateTime.now();
    final filteredIncomes = allExpenses.where((exp) {
      return exp.date.year == now.year && exp.date.month == now.month && exp.isIncome == true;
    }).toList();
    return filteredIncomes.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get balanceForMonth {
    return totalIncomeForMonth - totalAmountForMonth;
  }

  double averageOfPreviousMonths(bool enableIncomes) {
    final now = DateTime.now();
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    final Map<String, double> monthlyTotals = {};
    for (var expense in allExpenses) {
      if (expense.date.isBefore(firstDayOfCurrentMonth)) {
        if (!enableIncomes && expense.isIncome == true) continue;
        
        final monthKey = '${expense.date.year}-${expense.date.month}';
        
        double amount = expense.amount;
        if (enableIncomes) {
            amount = expense.isIncome == true ? expense.amount : -expense.amount;
        } else {
            amount = expense.amount;
        }

        monthlyTotals.update(monthKey, (value) => value + amount,
            ifAbsent: () => amount);
      }
    }
    if (monthlyTotals.isEmpty) return 0.0;
    return monthlyTotals.values.reduce((a, b) => a + b) / monthlyTotals.length;
  }

  double percentageChangeFromAverage(bool enableIncomes) {
    final average = averageOfPreviousMonths(enableIncomes);
    if (average == 0) return 0.0;
    
    if (enableIncomes) {
        return ((balanceForMonth - average) / average.abs()) * 100;
    } else {
        return ((totalAmountForMonth - average) / average.abs()) * 100;
    }
  }

  List<Expense> getRecentExpenses(bool enableIncomes) {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

    List<Expense> sortedExpenses = allExpenses.where((exp) {
      if (!enableIncomes && exp.isIncome == true) return false;
      return exp.date.isBefore(endOfToday) ||
          exp.date.isAtSameMomentAs(endOfToday);
    }).toList();

    sortedExpenses.sort((a, b) => b.date.compareTo(a.date));
    return sortedExpenses.take(5).toList();
  }

  void clearData() {
    notifyListeners();
  }
}

final dashboardViewModelProvider =
    ChangeNotifierProvider<DashboardViewModel>((ref) => DashboardViewModel(
          categoryViewModel: ref.read(categoryViewModelProvider),
          expenseViewModel: ref.read(expenseViewModelProvider),
          credentialViewModel: ref.read(credentialViewModelProvider),
        ));
