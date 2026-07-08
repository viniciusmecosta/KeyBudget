import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
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
  int _trendMonthsCount = 3;
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

  int get trendMonthsCount => _trendMonthsCount;

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

  void setTrendMonthsCount(int count) {
    _trendMonthsCount = count;
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
    return allExpenses.where((exp) => exp.isIncome != true).fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalCurrentMonth {
    final targetMonth = _selectedMonthForCategory ?? DateTime.now();
    return allExpenses
        .where(
            (exp) => exp.date.year == targetMonth.year && exp.date.month == targetMonth.month && exp.isIncome != true)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get incomesCurrentMonth {
    final targetMonth = _selectedMonthForCategory ?? DateTime.now();
    return allExpenses
        .where(
            (exp) => exp.date.year == targetMonth.year && exp.date.month == targetMonth.month && exp.isIncome == true)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get balanceCurrentMonth => incomesCurrentMonth - totalCurrentMonth;

  Map<String, double> get monthlyTotals {
    final Map<String, double> data = {};
    for (var expense in allExpenses) {
      if (expense.isIncome == true) continue;
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
    final targetMonth = _selectedMonthForCategory ?? DateTime.now();
    final lastMonth = DateTime(targetMonth.year, targetMonth.month - 1);
    return allExpenses
        .where(
            (exp) => exp.date.year == lastMonth.year && exp.date.month == lastMonth.month && exp.isIncome != true)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get lastMonthIncome {
    final targetMonth = _selectedMonthForCategory ?? DateTime.now();
    final lastMonth = DateTime(targetMonth.year, targetMonth.month - 1);
    return allExpenses
        .where(
            (exp) => exp.date.year == lastMonth.year && exp.date.month == lastMonth.month && exp.isIncome == true)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get lastMonthBalance => lastMonthIncome - lastMonthExpense;

  double get percentageChangeFromLastMonth {
    final lastMonth = lastMonthExpense;
    final currentMonth = totalCurrentMonth;
    if (lastMonth == 0) return 0.0;
    return ((currentMonth - lastMonth) / lastMonth) * 100;
  }

  double get incomesPercentageChangeFromLastMonth {
    final lastMonth = lastMonthIncome;
    final currentMonth = incomesCurrentMonth;
    if (lastMonth == 0) return 0.0;
    return ((currentMonth - lastMonth) / lastMonth) * 100;
  }

  double get balancePercentageChangeFromLastMonth {
    final lastMonth = lastMonthBalance;
    final currentMonth = balanceCurrentMonth;
    if (lastMonth == 0) return 0.0;
    return ((currentMonth - lastMonth) / lastMonth.abs()) * 100;
  }

  Map<String, double> get lastNMonthsData {
    final Map<String, double> data = {};

    final now = DateTime.now();
    final currentPeriodEndDate = DateTime(now.year, now.month + 1, 0);
    final currentPeriodStartDate = DateTime(currentPeriodEndDate.year,
        currentPeriodEndDate.month - _trendMonthsCount + 1, 1);

    for (int i = 0; i < _trendMonthsCount; i++) {
      final date = DateTime(
          currentPeriodStartDate.year, currentPeriodStartDate.month + i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      data[monthKey] = 0.0;
    }

    final expensesInPeriod = allExpenses.where((exp) {
      return exp.isIncome != true &&
          !exp.date.isBefore(currentPeriodStartDate) &&
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

  Map<String, ({double incomes, double expenses})> get lastNMonthsTrendData {
    final Map<String, ({double incomes, double expenses})> data = {};

    final now = DateTime.now();
    final currentPeriodEndDate = DateTime(now.year, now.month + 1, 0);
    final currentPeriodStartDate = DateTime(currentPeriodEndDate.year,
        currentPeriodEndDate.month - _trendMonthsCount + 1, 1);

    for (int i = 0; i < _trendMonthsCount; i++) {
      final date = DateTime(
          currentPeriodStartDate.year, currentPeriodStartDate.month + i, 1);
      final monthKey = DateFormat('yyyy-MM').format(date);
      data[monthKey] = (incomes: 0.0, expenses: 0.0);
    }

    final inPeriod = allExpenses.where((exp) {
      return !exp.date.isBefore(currentPeriodStartDate) &&
          !exp.date.isAfter(currentPeriodEndDate);
    });

    for (var item in inPeriod) {
      final monthKey = DateFormat('yyyy-MM').format(item.date);
      if (data.containsKey(monthKey)) {
        final existing = data[monthKey]!;
        if (item.isIncome == true) {
          data[monthKey] = (incomes: existing.incomes + item.amount, expenses: existing.expenses);
        } else {
          data[monthKey] = (incomes: existing.incomes, expenses: existing.expenses + item.amount);
        }
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
    final Map<ExpenseCategory, double> data = {};
    final targetMonth = _selectedMonthForCategory ?? DateTime.now();

    final expensesInMonth = allExpenses.where((exp) {
      return exp.isIncome != true &&
          exp.date.year == targetMonth.year &&
          exp.date.month == targetMonth.month;
    });

    for (var expense in expensesInMonth) {
      final category = categoryViewModel.getCategoryById(expense.categoryId);
      if (category != null) {
        data.update(category, (value) => value + expense.amount,
            ifAbsent: () => expense.amount);
      }
    }
    return data;
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

final analysisViewModelProvider =
    ChangeNotifierProvider<AnalysisViewModel>((ref) => AnalysisViewModel(
          categoryViewModel: ref.read(categoryViewModelProvider),
          expenseViewModel: ref.read(expenseViewModelProvider),
        ));
