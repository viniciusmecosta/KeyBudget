import 'package:key_budget/core/time/date_range.dart';

class AnalysisQuery {
  final DateRange range;
  final String currency;
  final Set<String>? selectedCategoryIds;
  final bool includeIncome;
  final bool includeExpenses;
  final int? trendMonthsCount;
  final String? searchQuery;

  const AnalysisQuery({
    required this.range,
    this.currency = 'BRL',
    this.selectedCategoryIds,
    this.includeIncome = true,
    this.includeExpenses = true,
    this.trendMonthsCount,
    this.searchQuery,
  });

  factory AnalysisQuery.forMonth(DateTime month, {bool includeIncome = true}) {
    return AnalysisQuery(
      range: DateRange.fromMonth(month.year, month.month),
      includeIncome: includeIncome,
    );
  }

  factory AnalysisQuery.forTrend({
    required DateTime referenceMonth,
    int monthsCount = 3,
    bool includeIncome = true,
  }) {
    final start = DateTime(
      referenceMonth.year,
      referenceMonth.month - monthsCount + 1,
      1,
    );
    final end = DateTime(referenceMonth.year, referenceMonth.month + 1, 1);
    return AnalysisQuery(
      range: DateRange(startInclusive: start, endExclusive: end),
      trendMonthsCount: monthsCount,
      includeIncome: includeIncome,
    );
  }

  AnalysisQuery copyWith({
    DateRange? range,
    String? currency,
    Set<String>? selectedCategoryIds,
    bool? includeIncome,
    bool? includeExpenses,
    int? trendMonthsCount,
    String? searchQuery,
  }) {
    return AnalysisQuery(
      range: range ?? this.range,
      currency: currency ?? this.currency,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      includeIncome: includeIncome ?? this.includeIncome,
      includeExpenses: includeExpenses ?? this.includeExpenses,
      trendMonthsCount: trendMonthsCount ?? this.trendMonthsCount,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisQuery &&
          runtimeType == other.runtimeType &&
          range == other.range &&
          currency == other.currency &&
          includeIncome == other.includeIncome &&
          includeExpenses == other.includeExpenses &&
          trendMonthsCount == other.trendMonthsCount &&
          searchQuery == other.searchQuery &&
          _setEquals(selectedCategoryIds, other.selectedCategoryIds);

  @override
  int get hashCode =>
      range.hashCode ^
      currency.hashCode ^
      includeIncome.hashCode ^
      includeExpenses.hashCode ^
      trendMonthsCount.hashCode ^
      searchQuery.hashCode;

  static bool _setEquals(Set<String>? a, Set<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.length == b.length && a.containsAll(b);
  }
}
