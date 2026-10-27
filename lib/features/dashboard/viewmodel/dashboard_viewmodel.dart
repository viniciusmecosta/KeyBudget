import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:passfin/core/models/expense_model.dart';
import 'package:passfin/core/money/money.dart';
import 'package:passfin/features/category/viewmodel/category_viewmodel.dart';
import 'package:passfin/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:passfin/features/expenses/viewmodel/expense_viewmodel.dart';

class DashboardViewModel extends ChangeNotifier {
  CategoryViewModel categoryViewModel;
  ExpenseViewModel expenseViewModel;
  CredentialViewModel credentialViewModel;
  int _refreshCount = 0;

  double _lastAnimatedTotalForMonth = 0;
  double _lastAnimatedBalanceForMonth = 0;

  DashboardViewModel({
    required this.categoryViewModel,
    required this.expenseViewModel,
    required this.credentialViewModel,
  }) {
    _addListeners();
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
  }

  void onAnimationStartedTo({required double total, required double balance}) {
    _lastAnimatedTotalForMonth = total;
    _lastAnimatedBalanceForMonth = balance;
  }

  void triggerRefresh() {
    _lastAnimatedTotalForMonth = 0;
    _lastAnimatedBalanceForMonth = 0;
    _refreshCount++;
    notifyListeners();
  }

  int get refreshCount => _refreshCount;

  double get lastAnimatedTotalForMonth => _lastAnimatedTotalForMonth;
  double get lastAnimatedBalanceForMonth => _lastAnimatedBalanceForMonth;

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
      return exp.date.year == now.year &&
          exp.date.month == now.month &&
          exp.isIncome != true;
    }).toList();
    final totalMinor = filteredExpenses.fold<int>(
      0,
      (sum, item) => sum + item.money.amountMinor,
    );
    return Money.fromCents(totalMinor).toDouble();
  }

  double get totalIncomeForMonth {
    final now = DateTime.now();
    final filteredIncomes = allExpenses.where((exp) {
      return exp.date.year == now.year &&
          exp.date.month == now.month &&
          exp.isIncome == true;
    }).toList();
    final totalMinor = filteredIncomes.fold<int>(
      0,
      (sum, item) => sum + item.money.amountMinor,
    );
    return Money.fromCents(totalMinor).toDouble();
  }

  static int scheduledMinorForMonth(
    List<Expense> expenses, {
    required DateTime now,
    required bool isIncome,
  }) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return expenses
        .where(
          (expense) =>
              expense.date.year == now.year &&
              expense.date.month == now.month &&
              !expense.date.isBefore(tomorrow) &&
              (expense.isIncome == true) == isIncome,
        )
        .fold<int>(0, (total, expense) => total + expense.money.amountMinor);
  }

  int get scheduledExpensesMinorForMonth =>
      scheduledMinorForMonth(allExpenses, now: DateTime.now(), isIncome: false);

  int get scheduledIncomesMinorForMonth =>
      scheduledMinorForMonth(allExpenses, now: DateTime.now(), isIncome: true);

  static int realizedMinorForMonth(
    List<Expense> expenses, {
    required DateTime now,
    required bool isIncome,
  }) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return expenses
        .where(
          (expense) =>
              expense.date.year == now.year &&
              expense.date.month == now.month &&
              expense.date.isBefore(tomorrow) &&
              (expense.isIncome == true) == isIncome,
        )
        .fold<int>(0, (total, expense) => total + expense.money.amountMinor);
  }

  double get realizedAmountForMonth => Money.fromCents(
    realizedMinorForMonth(allExpenses, now: DateTime.now(), isIncome: false),
  ).toDouble();

  double get realizedIncomeForMonth => Money.fromCents(
    realizedMinorForMonth(allExpenses, now: DateTime.now(), isIncome: true),
  ).toDouble();

  double get realizedBalanceForMonth =>
      realizedIncomeForMonth - realizedAmountForMonth;

  double get balanceForMonth {
    return totalIncomeForMonth - totalAmountForMonth;
  }

  double averageOfPreviousMonths(bool enableIncomes) {
    final now = DateTime.now();
    return averageOfEquivalentPreviousMonths(
      allExpenses,
      now: now,
      enableIncomes: enableIncomes,
    );
  }

  static double averageOfEquivalentPreviousMonths(
    List<Expense> expenses, {
    required DateTime now,
    required bool enableIncomes,
  }) {
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    final Map<String, double> monthlyTotals = {};
    for (final expense in expenses) {
      if (expense.date.isBefore(firstDayOfCurrentMonth)) {
        if (!enableIncomes && expense.isIncome == true) continue;

        final monthKey = '${expense.date.year}-${expense.date.month}';

        monthlyTotals.putIfAbsent(monthKey, () => 0);
        if (expense.date.day > now.day) continue;

        double amount = expense.amount;
        if (enableIncomes) {
          amount = expense.isIncome == true ? expense.amount : -expense.amount;
        } else {
          amount = expense.amount;
        }

        monthlyTotals.update(
          monthKey,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
      }
    }
    if (monthlyTotals.isEmpty) return 0.0;
    return monthlyTotals.values.reduce((a, b) => a + b) / monthlyTotals.length;
  }

  double percentageChangeFromAverage(bool enableIncomes) {
    final average = averageOfPreviousMonths(enableIncomes);
    if (average == 0) return 0.0;

    if (enableIncomes) {
      return ((realizedBalanceForMonth - average) / average.abs()) * 100;
    } else {
      return ((realizedAmountForMonth - average) / average.abs()) * 100;
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

final dashboardViewModelProvider = ChangeNotifierProvider<DashboardViewModel>(
  (ref) => DashboardViewModel(
    categoryViewModel: ref.read(categoryViewModelProvider),
    expenseViewModel: ref.read(expenseViewModelProvider),
    credentialViewModel: ref.read(credentialViewModelProvider),
  ),
);
