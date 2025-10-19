import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class AnalysisViewModel extends ChangeNotifier {
  CategoryViewModel categoryViewModel;
  ExpenseViewModel expenseViewModel;
  DateTime? _selectedMonthForCategory;
  int _periodOffset = 0;
  int _selectedMonthsCount = 6;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _useCustomRange = false;

  AnalysisViewModel({
    required this.categoryViewModel,
    required this.expenseViewModel,
  }) {
    _initialize();
  }

  void updateDependencies({
    required CategoryViewModel categoryViewModel,
    required ExpenseViewModel expenseViewModel,
  }) {
    if (this.categoryViewModel != categoryViewModel ||
        this.expenseViewModel != expenseViewModel) {
      this.categoryViewModel = categoryViewModel;
      this.expenseViewModel = expenseViewModel;
      _initialize();
      notifyListeners();
    }
  }

  void _initialize() {
    allExpenses.sort((a, b) => a.date.compareTo(b.date));
    if (availableMonthsForFilter.isNotEmpty) {
      _selectedMonthForCategory = availableMonthsForFilter.first;
    } else {
      final now = DateTime.now();
      _selectedMonthForCategory = DateTime(now.year, now.month);
    }
  }

  List<Expense> get allExpenses {
    final expenses = List<Expense>.from(expenseViewModel.allExpenses);
    expenses.sort((a, b) => a.date.compareTo(b.date));
    return expenses;
  }

  bool get isLoading =>
      categoryViewModel.isLoading || expenseViewModel.isLoading;

  DateTime? get selectedMonthForCategory => _selectedMonthForCategory;

  int get selectedMonthsCount => _selectedMonthsCount;

  bool get useCustomRange => _useCustomRange;

  DateTime? get customStartDate => _customStartDate;

  DateTime? get customEndDate => _customEndDate;

  List<int> get availableMonthsCounts => [3, 6, 9, 12];

  bool get canGoToPreviousPeriod {
    if (allExpenses.isEmpty) return false;
    final firstExpenseDate = allExpenses.first.date;
    final now = DateTime.now();
    final nextPeriodOffset = _periodOffset + 1;
    final nextStartDate = DateTime(
        now.year,
        now.month -
            _selectedMonthsCount +
            1 -
            (nextPeriodOffset * _selectedMonthsCount),
        1);
    return !nextStartDate.isBefore(firstExpenseDate);
  }

  bool get canGoToNextPeriod => _periodOffset > 0;

  void setSelectedMonthForCategory(DateTime? month) {
    _selectedMonthForCategory = month;
    notifyListeners();
  }

  void setSelectedMonthsCount(int count) {
    _selectedMonthsCount = count;
    _periodOffset = 0;
    _useCustomRange = false;
    notifyListeners();
  }

  void setCustomDateRange(DateTime? startDate, DateTime? endDate) {
    _customStartDate = startDate;
    _customEndDate = endDate;
    _useCustomRange = startDate != null && endDate != null;
    if (_useCustomRange) {
      _periodOffset = 0;
    }
    notifyListeners();
  }

  void clearCustomRange() {
    _useCustomRange = false;
    _customStartDate = null;
    _customEndDate = null;
    notifyListeners();
  }

  void changePeriod(int direction) {
    if (_useCustomRange) return;

    if (direction > 0 && canGoToPreviousPeriod) {
      _periodOffset++;
    } else if (direction < 0 && canGoToNextPeriod) {
      _periodOffset--;
    }
    notifyListeners();
  }

  double get totalOverall {
    return allExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalCurrentMonth {
    final now = DateTime.now();
    return allExpenses
        .where(
            (exp) => exp.date.year == now.year && exp.date.month == now.month)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  Map<String, double> get monthlyTotals {
    final Map<String, double> data = {};
    for (var expense in allExpenses) {
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

  Map<String, double> get lastNMonthsData {
    final Map<String, double> data = {};

    if (_useCustomRange && _customStartDate != null && _customEndDate != null) {
      return _getCustomRangeData();
    }

    final now = DateTime.now();
    final currentPeriodEndDate = DateTime(
        now.year, now.month - (_periodOffset * _selectedMonthsCount) + 1, 0);
    final currentPeriodStartDate = DateTime(currentPeriodEndDate.year,
        currentPeriodEndDate.month - _selectedMonthsCount + 1, 1);

    for (int i = 0; i < _selectedMonthsCount; i++) {
      final date = DateTime(
          currentPeriodStartDate.year, currentPeriodStartDate.month + i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      data[monthKey] = 0.0;
    }

    final expensesInPeriod = allExpenses.where((exp) {
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

  Map<String, double> _getCustomRangeData() {
    final Map<String, double> data = {};

    if (_customStartDate == null || _customEndDate == null) return data;

    DateTime current =
        DateTime(_customStartDate!.year, _customStartDate!.month, 1);
    final end = DateTime(_customEndDate!.year, _customEndDate!.month, 1);

    while (!current.isAfter(end)) {
      final monthKey = DateFormat('yyyy-MM').format(current);
      data[monthKey] = 0.0;
      current = DateTime(current.year, current.month + 1, 1);
    }

    final expensesInRange = allExpenses.where((exp) {
      final expenseMonth = DateTime(exp.date.year, exp.date.month, 1);
      return !expenseMonth.isBefore(
              DateTime(_customStartDate!.year, _customStartDate!.month, 1)) &&
          !expenseMonth.isAfter(
              DateTime(_customEndDate!.year, _customEndDate!.month, 1));
    });

    for (var expense in expensesInRange) {
      final monthKey = DateFormat('yyyy-MM').format(expense.date);
      if (data.containsKey(monthKey)) {
        data.update(monthKey, (value) => value + expense.amount);
      }
    }

    return data;
  }

  Map<String, double> get last6MonthsData => lastNMonthsData;

  String get currentPeriodLabel {
    if (_useCustomRange && _customStartDate != null && _customEndDate != null) {
      return '${DateFormat.yMMM('pt_BR').format(_customStartDate!)} - ${DateFormat.yMMM('pt_BR').format(_customEndDate!)}';
    }

    final data = lastNMonthsData;
    if (data.isEmpty) return '';

    final entries = data.entries.toList();
    final firstMonth = DateFormat('yyyy-MM').parse(entries.first.key);
    final lastMonth = DateFormat('yyyy-MM').parse(entries.last.key);

    return '${DateFormat.yMMM('pt_BR').format(firstMonth)} - ${DateFormat.yMMM('pt_BR').format(lastMonth)}';
  }

  List<DateTime> get availableMonthsForFilter {
    if (allExpenses.isEmpty) return [];
    final uniqueMonths = allExpenses
        .map((e) => DateTime(e.date.year, e.date.month))
        .toSet()
        .toList();
    uniqueMonths.sort((a, b) => b.compareTo(a));
    return uniqueMonths;
  }

  DateTimeRange? get availableDateRange {
    if (allExpenses.isEmpty) return null;
    final sortedExpenses = List<Expense>.from(allExpenses)
      ..sort((a, b) => a.date.compareTo(b.date));
    return DateTimeRange(
      start: DateTime(
          sortedExpenses.first.date.year, sortedExpenses.first.date.month, 1),
      end: DateTime(
          sortedExpenses.last.date.year, sortedExpenses.last.date.month + 1, 0),
    );
  }

  Map<ExpenseCategory, double> get expensesByCategoryForSelectedMonth {
    final Map<ExpenseCategory, double> totals = {};
    if (_selectedMonthForCategory == null) return totals;

    final monthExpenses = allExpenses.where((exp) =>
        exp.date.year == _selectedMonthForCategory!.year &&
        exp.date.month == _selectedMonthForCategory!.month);

    for (var expense in monthExpenses) {
      final category = categoryViewModel.getCategoryById(expense.categoryId);
      if (category != null) {
        totals.update(category, (value) => value + expense.amount,
            ifAbsent: () => expense.amount);
      }
    }
    return totals;
  }

  Map<String, double> get currentPeriodStats {
    final data = lastNMonthsData;
    final values = data.values.where((v) => v > 0).toList();

    if (values.isEmpty) {
      return {
        'total': 0.0,
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
      };
    }

    return {
      'total': values.fold(0.0, (a, b) => a + b),
      'average': values.fold(0.0, (a, b) => a + b) / values.length,
      'highest': values.reduce((a, b) => a > b ? a : b),
      'lowest': values.reduce((a, b) => a < b ? a : b),
    };
  }
}
