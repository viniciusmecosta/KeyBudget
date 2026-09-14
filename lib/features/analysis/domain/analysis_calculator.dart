import 'package:intl/intl.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'analysis_query.dart';
import 'analysis_snapshot.dart';

class AnalysisCalculator {

  static AnalysisSnapshot calculate({
    required AnalysisQuery query,
    required List<Expense> expenses,
    required List<ExpenseCategory> categories,
    required DateTime capturedAt,
  }) {
    final List<String> diagnostics = [];
    final Map<String, ExpenseCategory> categoryMap = {
      for (final c in categories)
        if (c.id != null) c.id!: c,
    };

    final eligibleExpenses = expenses.where((e) {
      if (!query.range.contains(e.date)) return false;
      if (query.selectedCategoryIds != null) {
        if (!query.selectedCategoryIds!.contains(e.categoryId)) return false;
      }
      if (query.searchQuery != null && query.searchQuery!.trim().isNotEmpty) {
        final q = query.searchQuery!.trim().toLowerCase();
        final matchMotiv = e.motivation?.toLowerCase().contains(q) ?? false;
        final matchLoc = e.location?.toLowerCase().contains(q) ?? false;
        if (!matchMotiv && !matchLoc) return false;
      }
      return true;
    }).toList();

    int totalIncomeMinor = 0;
    int totalExpenseMinor = 0;
    int incomeCount = 0;
    int expenseCount = 0;
    final List<String> consideredIds = [];

    final Map<ExpenseCategory, int> categoryCentsMap = {};
    final Map<ExpenseCategory, int> categoryCountMap = {};

    for (final exp in eligibleExpenses) {
      if (exp.id != null) consideredIds.add(exp.id!);

      final isIncome = exp.isIncome ?? false;
      final cents = exp.money.amountMinor;

      if (isIncome) {
        if (query.includeIncome) {
          totalIncomeMinor += cents;
          incomeCount++;
        }
      } else {
        if (query.includeExpenses) {
          totalExpenseMinor += cents;
          expenseCount++;

          ExpenseCategory resolvedCategory;
          if (exp.categoryId == null || exp.categoryId!.trim().isEmpty) {
            resolvedCategory = ExpenseCategory.uncategorized();
          } else {
            final existing = categoryMap[exp.categoryId!];
            if (existing != null) {
              resolvedCategory = existing;
            } else {
              resolvedCategory = ExpenseCategory.orphan(exp.categoryId!);
            }
          }

          categoryCentsMap[resolvedCategory] =
              (categoryCentsMap[resolvedCategory] ?? 0) + cents;
          categoryCountMap[resolvedCategory] =
              (categoryCountMap[resolvedCategory] ?? 0) + 1;
        }
      }
    }

    final totalExpenses = Money.fromCents(totalExpenseMinor);
    final totalIncomes = Money.fromCents(totalIncomeMinor);
    final balance = Money.fromCents(totalIncomeMinor - totalExpenseMinor);

    final List<AnalysisCategoryGroup> categoryDistribution = [];
    final sortedCategories = categoryCentsMap.keys.toList()
      ..sort((a, b) {
        final centsA = categoryCentsMap[a] ?? 0;
        final centsB = categoryCentsMap[b] ?? 0;
        final cmp = centsB.compareTo(centsA);
        if (cmp != 0) return cmp;
        return a.name.compareTo(b.name);
      });

    for (final cat in sortedCategories) {
      final cents = categoryCentsMap[cat] ?? 0;
      final count = categoryCountMap[cat] ?? 0;
      final percentage = totalExpenseMinor > 0
          ? (cents / totalExpenseMinor) * 100.0
          : 0.0;

      categoryDistribution.add(
        AnalysisCategoryGroup(
          categoryId: cat.id ?? 'cat_${cat.name}',
          categoryName: cat.name,
          colorValue: cat.colorValue,
          iconCodePoint: cat.iconCodePoint,
          totalAmount: Money.fromCents(cents),
          itemsCount: count,
          percentage: percentage,
          category: cat,
        ),
      );
    }

    final List<MonthlyPoint> monthlySeries = _buildMonthlySeries(
      query: query,
      expenses: eligibleExpenses,
    );

    final calendarMonthsCount = monthlySeries.isNotEmpty
        ? monthlySeries.length
        : 1;

    final averageMonthlyExpenseCents = (totalExpenseMinor / calendarMonthsCount).round();
    final averageMonthlyExpense = Money.fromCents(averageMonthlyExpenseCents);

    return AnalysisSnapshot(
      query: query,
      capturedAt: capturedAt,
      consideredExpenseIds: consideredIds,
      resolvedCategories: categoryMap,
      totalExpenses: totalExpenses,
      totalIncomes: totalIncomes,
      balance: balance,
      monthlySeries: monthlySeries,
      categoryDistribution: categoryDistribution,
      totalCount: incomeCount + expenseCount,
      expenseCount: expenseCount,
      incomeCount: incomeCount,
      averageMonthlyExpense: averageMonthlyExpense,
      calendarMonthsCount: calendarMonthsCount,
      diagnostics: diagnostics,
    );
  }

  static List<MonthlyPoint> _buildMonthlySeries({
    required AnalysisQuery query,
    required List<Expense> expenses,
  }) {
    final start = query.range.startInclusive;

    final endInclusive = query.range.endExclusive.subtract(const Duration(milliseconds: 1));

    int currentYear = start.year;
    int currentMonth = start.month;
    final targetYear = endInclusive.year;
    final targetMonth = endInclusive.month;

    final List<({int year, int month})> monthList = [];
    while (currentYear < targetYear ||
        (currentYear == targetYear && currentMonth <= targetMonth)) {
      monthList.add((year: currentYear, month: currentMonth));
      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }

    final Map<String, int> incomeMap = {};
    final Map<String, int> expenseMap = {};
    final Map<String, int> incomeCountMap = {};
    final Map<String, int> expenseCountMap = {};

    for (final exp in expenses) {
      final key = DateFormat('yyyy-MM').format(exp.date);
      final isIncome = exp.isIncome ?? false;
      final cents = exp.money.amountMinor;

      if (isIncome) {
        if (query.includeIncome) {
          incomeMap[key] = (incomeMap[key] ?? 0) + cents;
          incomeCountMap[key] = (incomeCountMap[key] ?? 0) + 1;
        }
      } else {
        if (query.includeExpenses) {
          expenseMap[key] = (expenseMap[key] ?? 0) + cents;
          expenseCountMap[key] = (expenseCountMap[key] ?? 0) + 1;
        }
      }
    }

    final List<MonthlyPoint> points = [];
    for (final m in monthList) {
      final date = DateTime(m.year, m.month, 1);
      final label = DateFormat('yyyy-MM').format(date);

      final incCents = incomeMap[label] ?? 0;
      final expCents = expenseMap[label] ?? 0;
      final balCents = incCents - expCents;

      points.add(
        MonthlyPoint(
          year: m.year,
          month: m.month,
          label: label,
          incomeAmount: Money.fromCents(incCents),
          expenseAmount: Money.fromCents(expCents),
          balanceAmount: Money.fromCents(balCents),
          incomeCount: incomeCountMap[label] ?? 0,
          expenseCount: expenseCountMap[label] ?? 0,
        ),
      );
    }

    return points;
  }

  static double calculatePercentageChange({
    required Money current,
    required Money previous,
  }) {
    if (previous.amountMinor == 0) {
      if (current.amountMinor == 0) return 0.0;
      return 100.0;
    }
    final diff = current.amountMinor - previous.amountMinor;
    return (diff / previous.amountMinor.abs()) * 100.0;
  }
}
