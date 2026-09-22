import 'package:intl/intl.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'analysis_query.dart';

class MonthlyPoint {
  final int year;
  final int month;
  final String label;
  final Money incomeAmount;
  final Money expenseAmount;
  final Money balanceAmount;
  final int incomeCount;
  final int expenseCount;

  const MonthlyPoint({
    required this.year,
    required this.month,
    required this.label,
    required this.incomeAmount,
    required this.expenseAmount,
    required this.balanceAmount,
    required this.incomeCount,
    required this.expenseCount,
  });

  DateTime get date => DateTime(year, month, 1);
  String get formattedMonthName =>
      DateFormat.yMMMM('pt_BR').format(date);
}

class AnalysisCategoryGroup {
  final String categoryId;
  final String categoryName;
  final int colorValue;
  final int iconCodePoint;
  final Money totalAmount;
  final int itemsCount;
  final double percentage;
  final ExpenseCategory category;

  const AnalysisCategoryGroup({
    required this.categoryId,
    required this.categoryName,
    required this.colorValue,
    required this.iconCodePoint,
    required this.totalAmount,
    required this.itemsCount,
    required this.percentage,
    required this.category,
  });
}

class AnalysisSnapshot {
  final AnalysisQuery query;
  final DateTime capturedAt;
  final List<String> consideredExpenseIds;
  final Map<String, ExpenseCategory> resolvedCategories;
  final Money totalExpenses;
  final Money totalIncomes;
  final Money balance;
  final List<MonthlyPoint> monthlySeries;
  final List<AnalysisCategoryGroup> categoryDistribution;
  final int totalCount;
  final int expenseCount;
  final int incomeCount;
  final Money averageMonthlyExpense;
  final int calendarMonthsCount;
  final List<String> diagnostics;

  const AnalysisSnapshot({
    required this.query,
    required this.capturedAt,
    required this.consideredExpenseIds,
    required this.resolvedCategories,
    required this.totalExpenses,
    required this.totalIncomes,
    required this.balance,
    required this.monthlySeries,
    required this.categoryDistribution,
    required this.totalCount,
    required this.expenseCount,
    required this.incomeCount,
    required this.averageMonthlyExpense,
    required this.calendarMonthsCount,
    this.diagnostics = const [],
  });

  bool get isCategorySumExact {
    final catSumCents = categoryDistribution.fold<int>(
      0,
      (sum, g) => sum + g.totalAmount.amountMinor,
    );
    return catSumCents == totalExpenses.amountMinor;
  }

  bool get isBalanceExact {
    return balance.amountMinor == (totalIncomes.amountMinor - totalExpenses.amountMinor);
  }

  bool get isMonthlySeriesSumExact {
    final seriesSumCents = monthlySeries.fold<int>(
      0,
      (sum, p) => sum + p.expenseAmount.amountMinor,
    );
    return seriesSumCents == totalExpenses.amountMinor;
  }

  bool get isInvariantsValid =>
      isCategorySumExact && isBalanceExact && isMonthlySeriesSumExact;

  Map<ExpenseCategory, double> toLegacyCategoryMap() {
    final Map<ExpenseCategory, double> map = {};
    for (final group in categoryDistribution) {
      map[group.category] = group.totalAmount.amountMinor / 100.0;
    }
    return map;
  }

  Map<String, double> toLegacyMonthlyTotals() {
    final Map<String, double> map = {};
    for (final point in monthlySeries) {
      map[point.label] = point.expenseAmount.amountMinor / 100.0;
    }
    return map;
  }

  Map<String, ({double incomes, double expenses})> toLegacyTrendMap() {
    final Map<String, ({double incomes, double expenses})> map = {};
    for (final point in monthlySeries) {
      map[point.label] = (
        incomes: point.incomeAmount.amountMinor / 100.0,
        expenses: point.expenseAmount.amountMinor / 100.0,
      );
    }
    return map;
  }
}
