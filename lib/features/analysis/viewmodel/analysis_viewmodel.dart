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
  int _yearOffset = 0;

  bool get isLoading => _isLoading;
  DateTime? get selectedMonthForCategory => _selectedMonthForCategory;
  int get yearOffset => _yearOffset;

  bool get canGoToPreviousYear {
    if (_allExpenses.isEmpty) return false;
    final firstExpenseDate = _allExpenses.first.date;
    final now = DateTime.now();
    final targetYear = now.year + _yearOffset;
    return targetYear > firstExpenseDate.year;
  }

  bool get canGoToNextYear {
    if (_allExpenses.isEmpty) return false;
    final lastExpenseDate = _allExpenses.last.date;
    final now = DateTime.now();
    final targetYear = now.year + _yearOffset;
    return targetYear < lastExpenseDate.year;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchExpenses(String userId) async {
    _isLoading = true;
    notifyListeners();

    _allExpenses = await _expenseRepository.getExpensesForUser(userId);
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));

    if (availableMonthsForFilter.isNotEmpty) {
      _selectedMonthForCategory = availableMonthsForFilter.first;
    } else {
      final now = DateTime.now();
      _selectedMonthForCategory = DateTime(now.year, now.month);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSelectedMonthForCategory(DateTime? month) {
    _selectedMonthForCategory = month;
    notifyListeners();
  }

  void changeYear(int direction) {
    if (direction > 0 && canGoToNextYear) {
      _yearOffset += direction;
    } else if (direction < 0 && canGoToPreviousYear) {
      _yearOffset += direction;
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

  Map<String, double> get last12MonthsData {
    final Map<String, double> data = {};
    final now = DateTime.now();
    final targetYearDate = DateTime(now.year + _yearOffset, now.month, now.day);

    final endDate = DateTime(targetYearDate.year, targetYearDate.month + 1, 0);
    final startDate =
        DateTime(targetYearDate.year, targetYearDate.month - 11, 1);

    for (int i = 0; i < 12; i++) {
      final date = DateTime(startDate.year, startDate.month + i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      data[monthKey] = 0.0;
    }

    final expensesInPeriod = _allExpenses.where((exp) {
      return !exp.date.isBefore(startDate) && !exp.date.isAfter(endDate);
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
    _yearOffset = 0;
    notifyListeners();
  }
}
