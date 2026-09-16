import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:key_budget/core/time/date_range.dart';
import 'package:key_budget/features/analysis/domain/analysis_calculator.dart';
import 'package:key_budget/features/analysis/domain/analysis_query.dart';
import 'package:key_budget/features/analysis/domain/analysis_snapshot.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class AnalysisViewModel extends ChangeNotifier {
  CategoryViewModel _categoryViewModel;
  ExpenseViewModel _expenseViewModel;
  final AppClock _clock;

  DateTime? _selectedMonthForCategory;
  int _periodOffset = 0;
  int _selectedMonthsCount = 6;
  int _trendMonthsCount = 3;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _useCustomRange = false;

  AnalysisSnapshot? _cachedCurrentSnapshot;
  AnalysisSnapshot? _cachedSelectedMonthSnapshot;
  AnalysisSnapshot? _cachedTrendSnapshot;

  AnalysisViewModel({
    required this._categoryViewModel,
    required this._expenseViewModel,
    this._clock = const SystemAppClock(),
  }) {
    _categoryViewModel.addListener(_onDependencyChanged);
    _expenseViewModel.addListener(_onDependencyChanged);
    _initialize();
  }

  CategoryViewModel get categoryViewModel => _categoryViewModel;
  ExpenseViewModel get expenseViewModel => _expenseViewModel;

  void updateDependencies({
    required CategoryViewModel categoryViewModel,
    required ExpenseViewModel expenseViewModel,
  }) {
    bool changed = false;
    if (_categoryViewModel != categoryViewModel) {
      _categoryViewModel.removeListener(_onDependencyChanged);
      _categoryViewModel = categoryViewModel;
      _categoryViewModel.addListener(_onDependencyChanged);
      changed = true;
    }
    if (_expenseViewModel != expenseViewModel) {
      _expenseViewModel.removeListener(_onDependencyChanged);
      _expenseViewModel = expenseViewModel;
      _expenseViewModel.addListener(_onDependencyChanged);
      changed = true;
    }
    if (changed) {
      _invalidateSnapshots();
      notifyListeners();
    }
  }

  void _onDependencyChanged() {
    _invalidateSnapshots();
    notifyListeners();
  }

  void _invalidateSnapshots() {
    _cachedCurrentSnapshot = null;
    _cachedSelectedMonthSnapshot = null;
    _cachedTrendSnapshot = null;
  }

  void _initialize() {
    if (availableMonthsForFilter.isNotEmpty) {
      _selectedMonthForCategory = availableMonthsForFilter.first;
    } else {
      final now = _clock.now();
      _selectedMonthForCategory = DateTime(now.year, now.month);
    }
    _invalidateSnapshots();
  }

  List<Expense> get allExpenses {
    final expenses = List<Expense>.from(_expenseViewModel.allExpenses);
    expenses.sort((a, b) => a.date.compareTo(b.date));
    return expenses;
  }

  bool get isLoading =>
      _categoryViewModel.isLoading || _expenseViewModel.isLoading;

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
    final now = _clock.now();
    final nextPeriodOffset = _periodOffset + 1;
    final nextStartDate = DateTime(
      now.year,
      now.month -
          _selectedMonthsCount +
          1 -
          (nextPeriodOffset * _selectedMonthsCount),
      1,
    );
    return !nextStartDate.isBefore(firstExpenseDate);
  }

  bool get canGoToNextPeriod => _periodOffset > 0;

  void setSelectedMonthForCategory(DateTime? month) {
    if (_selectedMonthForCategory != month) {
      _selectedMonthForCategory = month;
      _invalidateSnapshots();
      notifyListeners();
    }
  }

  void setSelectedMonthsCount(int count) {
    _selectedMonthsCount = count;
    _periodOffset = 0;
    _useCustomRange = false;
    _invalidateSnapshots();
    notifyListeners();
  }

  void setTrendMonthsCount(int count) {
    if (_trendMonthsCount != count) {
      _trendMonthsCount = count;
      _cachedTrendSnapshot = null;
      notifyListeners();
    }
  }

  void setCustomDateRange(DateTime? startDate, DateTime? endDate) {
    _customStartDate = startDate;
    _customEndDate = endDate;
    _useCustomRange = startDate != null && endDate != null;
    if (_useCustomRange) {
      _periodOffset = 0;
    }
    _invalidateSnapshots();
    notifyListeners();
  }

  void clearCustomRange() {
    _useCustomRange = false;
    _customStartDate = null;
    _customEndDate = null;
    _invalidateSnapshots();
    notifyListeners();
  }

  void changePeriod(int direction) {
    if (_useCustomRange) return;

    if (direction > 0 && canGoToPreviousPeriod) {
      _periodOffset++;
      _invalidateSnapshots();
      notifyListeners();
    } else if (direction < 0 && canGoToNextPeriod) {
      _periodOffset--;
      _invalidateSnapshots();
      notifyListeners();
    }
  }

  DateTime get _effectiveReferenceMonth {
    if (_selectedMonthForCategory != null) {
      return _selectedMonthForCategory!;
    }
    final now = _clock.now();
    return DateTime(now.year, now.month);
  }

  DateRange get selectedMonthRange {
    final target = _effectiveReferenceMonth;
    return DateRange.fromMonth(target.year, target.month);
  }

  DateRange get lastMonthRange {
    final target = _effectiveReferenceMonth;
    return DateRange.fromMonth(target.year, target.month - 1);
  }

  AnalysisQuery get currentQuery {
    if (_useCustomRange && _customStartDate != null && _customEndDate != null) {
      final endExclusive = DateTime(
        _customEndDate!.year,
        _customEndDate!.month,
        _customEndDate!.day + 1,
      );
      return AnalysisQuery(
        range: DateRange(
          startInclusive: DateTime(
            _customStartDate!.year,
            _customStartDate!.month,
            _customStartDate!.day,
          ),
          endExclusive: endExclusive,
        ),
      );
    }
    return AnalysisQuery.forMonth(_effectiveReferenceMonth);
  }

  AnalysisSnapshot get currentSnapshot {
    return _cachedCurrentSnapshot ??= AnalysisCalculator.calculate(
      query: currentQuery,
      expenses: allExpenses,
      categories: _categoryViewModel.categories,
      capturedAt: _clock.now(),
    );
  }

  AnalysisSnapshot get selectedMonthSnapshot {
    return _cachedSelectedMonthSnapshot ??= AnalysisCalculator.calculate(
      query: AnalysisQuery.forMonth(_effectiveReferenceMonth),
      expenses: allExpenses,
      categories: _categoryViewModel.categories,
      capturedAt: _clock.now(),
    );
  }

  AnalysisSnapshot get trendSnapshot {
    return _cachedTrendSnapshot ??= AnalysisCalculator.calculate(
      query: AnalysisQuery.forTrend(
        referenceMonth: _effectiveReferenceMonth,
        monthsCount: _trendMonthsCount,
      ),
      expenses: allExpenses,
      categories: _categoryViewModel.categories,
      capturedAt: _clock.now(),
    );
  }

  AnalysisSnapshot get lastMonthSnapshot {
    return AnalysisCalculator.calculate(
      query: AnalysisQuery(range: lastMonthRange),
      expenses: allExpenses,
      categories: _categoryViewModel.categories,
      capturedAt: _clock.now(),
    );
  }

  AnalysisSnapshot createSnapshotForQuery(AnalysisQuery query) {
    return AnalysisCalculator.calculate(
      query: query,
      expenses: allExpenses,
      categories: _categoryViewModel.categories,
      capturedAt: _clock.now(),
    );
  }

  double get totalOverall {
    final totalMinor = allExpenses
        .where((exp) => exp.isIncome != true)
        .fold<int>(0, (sum, item) => sum + item.money.amountMinor);
    return Money.fromCents(totalMinor).toDouble();
  }

  double get totalCurrentMonth =>
      selectedMonthSnapshot.totalExpenses.amountMinor / 100.0;

  double get incomesCurrentMonth =>
      selectedMonthSnapshot.totalIncomes.amountMinor / 100.0;

  double get balanceCurrentMonth =>
      selectedMonthSnapshot.balance.amountMinor / 100.0;

  Map<String, double> get monthlyTotals =>
      trendSnapshot.toLegacyMonthlyTotals();

  double get averageMonthlyExpense =>
      trendSnapshot.averageMonthlyExpense.amountMinor / 100.0;

  double get lastMonthExpense =>
      lastMonthSnapshot.totalExpenses.amountMinor / 100.0;

  double get lastMonthIncome =>
      lastMonthSnapshot.totalIncomes.amountMinor / 100.0;

  double get lastMonthBalance => lastMonthSnapshot.balance.amountMinor / 100.0;

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

  String get expenseChangePercentageLabel {
    if (lastMonthExpense == 0) return 'Sem base de comparação';
    final p = percentageChangeFromLastMonth;
    final prefix = p > 0 ? '+' : '';
    return '$prefix${p.toStringAsFixed(1)}%';
  }

  Map<String, double> get lastNMonthsData =>
      trendSnapshot.toLegacyMonthlyTotals();

  Map<String, ({double incomes, double expenses})> get lastNMonthsTrendData =>
      trendSnapshot.toLegacyTrendMap();

  Map<String, double> get last6MonthsData => lastNMonthsData;

  String get currentPeriodLabel {
    if (_useCustomRange && _customStartDate != null && _customEndDate != null) {
      return '${DateFormat.yMMM('pt_BR').format(_customStartDate!)} - ${DateFormat.yMMM('pt_BR').format(_customEndDate!)}';
    }
    final points = trendSnapshot.monthlySeries;
    if (points.isEmpty) return '';
    final first = points.first.date;
    final last = points.last.date;
    return '${DateFormat.yMMM('pt_BR').format(first)} - ${DateFormat.yMMM('pt_BR').format(last)}';
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
        sortedExpenses.first.date.year,
        sortedExpenses.first.date.month,
        1,
      ),
      end: DateTime(
        sortedExpenses.last.date.year,
        sortedExpenses.last.date.month + 1,
        0,
      ),
    );
  }

  Map<ExpenseCategory, double> get expensesByCategoryForSelectedMonth =>
      selectedMonthSnapshot.toLegacyCategoryMap();

  Map<String, double> get currentPeriodStats {
    final values = trendSnapshot.monthlySeries
        .map((p) => p.expenseAmount.amountMinor / 100.0)
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) {
      return {'total': 0.0, 'average': 0.0, 'highest': 0.0, 'lowest': 0.0};
    }

    return {
      'total': values.fold(0.0, (a, b) => a + b),
      'average': values.fold(0.0, (a, b) => a + b) / values.length,
      'highest': values.reduce((a, b) => a > b ? a : b),
      'lowest': values.reduce((a, b) => a < b ? a : b),
    };
  }

  @override
  void dispose() {
    _categoryViewModel.removeListener(_onDependencyChanged);
    _expenseViewModel.removeListener(_onDependencyChanged);
    super.dispose();
  }
}

final analysisViewModelProvider = ChangeNotifierProvider<AnalysisViewModel>(
  (ref) => AnalysisViewModel(
    categoryViewModel: ref.read(categoryViewModelProvider),
    expenseViewModel: ref.read(expenseViewModelProvider),
  ),
);
