import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/models/expense_category.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class AnalysisViewModel extends ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();

  List<Expense> _allExpenses = [];
  bool _isLoading = false;
  DateTime? _selectedMonthForCategory;
  int _periodOffset = 0;

  bool get isLoading => _isLoading;

  DateTime? get selectedMonthForCategory => _selectedMonthForCategory;

  bool get canGoToPreviousPeriod {
    if (_allExpenses.isEmpty) return false;
    final firstExpenseDate = _allExpenses.first.date;
    final now = DateTime.now();
    final nextPeriodOffset = _periodOffset + 1;
    final nextStartDate =
        DateTime(now.year, now.month - 5 - (nextPeriodOffset * 6), 1);
    return !nextStartDate.isBefore(firstExpenseDate);
  }

  bool get canGoToNextPeriod {
    return _periodOffset > 0;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchExpenses(String userId) async {
    _setLoading(true);
    _allExpenses = await _expenseRepository.getExpensesForUser(userId);
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));
    if (availableMonthsForFilter.isNotEmpty) {
      _selectedMonthForCategory = availableMonthsForFilter.first;
    } else {
      final now = DateTime.now();
      _selectedMonthForCategory = DateTime(now.year, now.month);
    }
    _setLoading(false);
  }

  void setSelectedMonthForCategory(DateTime? month) {
    _selectedMonthForCategory = month;
    notifyListeners();
  }

  void changePeriod(int direction) {
    if (direction > 0 && canGoToPreviousPeriod) {
      _periodOffset++;
    } else if (direction < 0 && canGoToNextPeriod) {
      _periodOffset--;
    }
    notifyListeners();
  }

  double get totalOverall {
    return _allExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalCurrentMonth {
    final now = DateTime.now();
    return _allExpenses
        .where(
            (exp) => exp.date.year == now.year && exp.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> get monthlyTotals {
    final Map<String, double> data = {};
    for (var expense in _allExpenses) {
      final monthKey = DateFormat('yyyy-MM').format(expense.date);
      data.update(monthKey, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }
    return data;
  }

  double get averageMonthlyExpense {
    final totals = monthlyTotals;
    if (totals.isEmpty) return 0.0;
    return totals.values.reduce((a, b) => a + b) / totals.length;
  }

  double get lastMonthExpense {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastMonthKey = DateFormat('yyyy-MM').format(lastMonth);
    return monthlyTotals[lastMonthKey] ?? 0.0;
  }

  double get percentageChangeFromLastMonth {
    final lastMonth = lastMonthExpense;
    final currentMonth = totalCurrentMonth;
    if (lastMonth == 0) return 0.0;
    return ((currentMonth - lastMonth) / lastMonth) * 100;
  }

  Map<String, double> get last6MonthsData {
    final Map<String, double> data = {};
    final now = DateTime.now();

    final currentPeriodEndDate =
        DateTime(now.year, now.month - (_periodOffset * 6) + 1, 0);
    final currentPeriodStartDate =
        DateTime(currentPeriodEndDate.year, currentPeriodEndDate.month - 5, 1);

    for (int i = 0; i < 6; i++) {
      final date = DateTime(
          currentPeriodStartDate.year, currentPeriodStartDate.month + i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      data[monthKey] = 0.0;
    }

    final expensesInPeriod = _allExpenses.where((exp) {
      return !exp.date.isBefore(currentPeriodStartDate) &&
          !exp.date.isAfter(currentPeriodEndDate);
    });

    for (var expense in expensesInPeriod) {
      final monthKey = DateFormat('yyyy-MM').format(expense.date);
      if (data.containsKey(monthKey)) {
        data.update(monthKey, (value) => value + expense.amount);
      }
    }
    return data;
  }

  List<DateTime> get availableMonthsForFilter {
    if (_allExpenses.isEmpty) return [];
    final uniqueMonths = _allExpenses
        .map((e) => DateTime(e.date.year, e.date.month))
        .toSet()
        .toList();
    uniqueMonths.sort((a, b) => b.compareTo(a));
    return uniqueMonths;
  }

  Map<ExpenseCategory, double> get expensesByCategoryForSelectedMonth {
    final Map<ExpenseCategory, double> totals = {};
    if (_selectedMonthForCategory == null) return totals;
    final monthExpenses = _allExpenses.where((exp) =>
        exp.date.year == _selectedMonthForCategory!.year &&
        exp.date.month == _selectedMonthForCategory!.month);
    for (var expense in monthExpenses) {
      final category = expense.category ?? ExpenseCategory.outros;
      totals.update(category, (value) => value + expense.amount,
          ifAbsent: () => expense.amount);
    }
    return totals;
  }

  void clearData() {
    _allExpenses = [];
    _isLoading = false;
    final now = DateTime.now();
    _selectedMonthForCategory = DateTime(now.year, now.month);
    _periodOffset = 0;
    notifyListeners();
  }
}
