import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/money/money.dart';

enum RecurrenceFrequency { daily, weekly, monthly }

extension RecurrenceFrequencyExtension on RecurrenceFrequency {
  String get nameInPortuguese {
    switch (this) {
      case RecurrenceFrequency.daily:
        return 'Diária';
      case RecurrenceFrequency.weekly:
        return 'Semanal';
      case RecurrenceFrequency.monthly:
        return 'Mensal';
    }
  }
}

class RecurringExpense {
  final String? id;
  final double amount;
  final int? amountMinor;
  final String? currency;
  final int? moneyVersion;
  final num? rawAmount;
  final bool isLegacyApproximate;
  final bool hasMoneyInconsistency;
  final String? categoryId;
  final String? motivation;
  final String? location;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final int? monthOfYear;
  final DateTime? lastInstanceDate;
  final bool? isIncome;
  final int advanceGenerationCount;
  final int? engineVersion;
  final int? scheduleVersion;
  final String? generationState;
  final int? generationRevision;
  final Map<String, dynamic> unmappedData;

  RecurringExpense({
    this.id,
    required this.amount,
    this.amountMinor,
    this.currency,
    this.moneyVersion,
    this.rawAmount,
    this.isLegacyApproximate = false,
    this.hasMoneyInconsistency = false,
    this.categoryId,
    this.motivation,
    this.location,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.dayOfWeek,
    this.dayOfMonth,
    this.monthOfYear,
    this.lastInstanceDate,
    this.isIncome,
    this.advanceGenerationCount = 0,
    this.engineVersion,
    this.scheduleVersion,
    this.generationState,
    this.generationRevision,
    Map<String, dynamic>? unmappedData,
  }) : unmappedData = unmappedData != null
            ? Map.unmodifiable(unmappedData)
            : const {};

  factory RecurringExpense.withMoney({
    String? id,
    required Money money,
    String? categoryId,
    String? motivation,
    String? location,
    required RecurrenceFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    int? dayOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    DateTime? lastInstanceDate,
    bool? isIncome,
    int advanceGenerationCount = 0,
    int? engineVersion,
    int? scheduleVersion,
    String? generationState,
    int? generationRevision,
    Map<String, dynamic>? unmappedData,
  }) {
    return RecurringExpense(
      id: id,
      amount: money.toDouble(),
      amountMinor: money.amountMinor,
      currency: money.currency,
      moneyVersion: 1,
      rawAmount: money.toDouble(),
      categoryId: categoryId,
      motivation: motivation,
      location: location,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      monthOfYear: monthOfYear,
      lastInstanceDate: lastInstanceDate,
      isIncome: isIncome,
      advanceGenerationCount: advanceGenerationCount,
      engineVersion: engineVersion ?? 1,
      scheduleVersion: scheduleVersion ?? 1,
      generationState: generationState ?? 'ready',
      generationRevision: generationRevision ?? 1,
      unmappedData: unmappedData,
    );
  }

  Money get money {
    if (amountMinor != null) {
      return Money.fromCents(amountMinor!, currency: currency ?? 'BRL');
    }
    return Money.fromNumWithHalfAwayFromZero(
      rawAmount ?? amount,
      currency: currency ?? 'BRL',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      ...unmappedData,
      'categoryId': categoryId,
      'motivation': motivation,
      'location': location,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
      'monthOfYear': monthOfYear,
      'lastInstanceDate': lastInstanceDate != null
          ? Timestamp.fromDate(lastInstanceDate!)
          : null,
      'isIncome': isIncome,
      'advanceGenerationCount': advanceGenerationCount,
      'engineVersion': engineVersion,
      'scheduleVersion': scheduleVersion,
      'generationState': generationState,
      'generationRevision': generationRevision,
    };

    if (moneyVersion != null && amountMinor != null) {
      map['amountMinor'] = amountMinor;
      map['currency'] = currency ?? 'BRL';
      map['moneyVersion'] = moneyVersion;
      map['amount'] = amountMinor! / 100.0;
    } else {
      map['amount'] = rawAmount ?? amount;
      if (currency != null) map['currency'] = currency;
      if (moneyVersion != null) map['moneyVersion'] = moneyVersion;
    }

    return map;
  }

  factory RecurringExpense.fromMap(Map<String, dynamic> map, String id) {
    final rawAmountVal = map['amount'];
    if (rawAmountVal == null) {
      throw FormatException('O campo amount é obrigatório para RecurringExpense $id');
    }
    if (rawAmountVal is! num) {
      throw FormatException('O campo amount deve ser numérico para RecurringExpense $id');
    }
    if (rawAmountVal.isNaN || rawAmountVal.isInfinite) {
      throw FormatException(
        'O campo amount não pode ser NaN ou infinito para RecurringExpense $id',
      );
    }

    final rawAmount = rawAmountVal;
    final storedAmountMinor = map['amountMinor'] as int?;
    final moneyVersion = map['moneyVersion'] as int?;
    final currency = map['currency'] as String? ?? 'BRL';

    int? effectiveAmountMinor;
    bool isApprox = false;
    bool hasInconsistency = false;

    if (storedAmountMinor != null) {
      final legacyEquivalent =
          Money.fromNumWithHalfAwayFromZero(rawAmount).amountMinor;
      if (storedAmountMinor == legacyEquivalent) {
        effectiveAmountMinor = storedAmountMinor;
      } else {
        hasInconsistency = true;
        effectiveAmountMinor = legacyEquivalent;
      }
    } else {
      isApprox = Money.hasMoreThanTwoDecimals(rawAmount);
      effectiveAmountMinor =
          Money.fromNumWithHalfAwayFromZero(rawAmount).amountMinor;
    }

    final knownKeys = {
      'amount',
      'amountMinor',
      'currency',
      'moneyVersion',
      'categoryId',
      'motivation',
      'location',
      'frequency',
      'startDate',
      'endDate',
      'dayOfWeek',
      'dayOfMonth',
      'monthOfYear',
      'lastInstanceDate',
      'isIncome',
      'advanceGenerationCount',
      'engineVersion',
      'scheduleVersion',
      'generationState',
      'generationRevision',
    };
    final unmapped = <String, dynamic>{};
    map.forEach((k, v) {
      if (!knownKeys.contains(k)) {
        unmapped[k] = v;
      }
    });

    DateTime parseDate(dynamic val, DateTime defaultDate) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.parse(val);
      return defaultDate;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.parse(val);
      return null;
    }

    return RecurringExpense(
      id: id,
      amount: rawAmount.toDouble(),
      amountMinor: effectiveAmountMinor,
      currency: currency,
      moneyVersion: moneyVersion,
      rawAmount: rawAmount,
      isLegacyApproximate: isApprox,
      hasMoneyInconsistency: hasInconsistency,
      categoryId: map['categoryId'],
      motivation: map['motivation'],
      location: map['location'],
      frequency: RecurrenceFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => RecurrenceFrequency.monthly,
      ),
      startDate: parseDate(map['startDate'], DateTime.now()),
      endDate: parseNullableDate(map['endDate']),
      dayOfWeek: map['dayOfWeek'] as int?,
      dayOfMonth: map['dayOfMonth'] as int?,
      monthOfYear: map['monthOfYear'] as int?,
      lastInstanceDate: parseNullableDate(map['lastInstanceDate']),
      isIncome: map['isIncome'] as bool?,
      advanceGenerationCount: (map['advanceGenerationCount'] as int?) ?? 0,
      engineVersion: map['engineVersion'] as int?,
      scheduleVersion: map['scheduleVersion'] as int?,
      generationState: map['generationState'] as String?,
      generationRevision: map['generationRevision'] as int?,
      unmappedData: unmapped,
    );
  }

  RecurringExpense copyWith({
    String? id,
    double? amount,
    int? amountMinor,
    String? currency,
    int? moneyVersion,
    num? rawAmount,
    bool? isLegacyApproximate,
    bool? hasMoneyInconsistency,
    String? categoryId,
    String? motivation,
    String? location,
    RecurrenceFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    int? dayOfWeek,
    int? dayOfMonth,
    int? monthOfYear,
    DateTime? lastInstanceDate,
    bool? isIncome,
    int? advanceGenerationCount,
    int? engineVersion,
    int? scheduleVersion,
    String? generationState,
    int? generationRevision,
    Map<String, dynamic>? unmappedData,
  }) {
    int? nextAmountMinor = amountMinor ?? this.amountMinor;
    num? nextRawAmount = rawAmount ?? this.rawAmount;
    int? nextMoneyVersion = moneyVersion ?? this.moneyVersion;

    if (amount != null && amount != this.amount && amountMinor == null) {
      final m = Money.fromNumWithHalfAwayFromZero(amount);
      nextAmountMinor = m.amountMinor;
      nextRawAmount = amount;
      nextMoneyVersion = 1;
    } else if (amountMinor != null &&
        amountMinor != this.amountMinor &&
        amount == null) {
      nextRawAmount = amountMinor / 100.0;
      nextMoneyVersion = 1;
    }

    return RecurringExpense(
      id: id ?? this.id,
      amount: amount ??
          (amountMinor != null ? amountMinor / 100.0 : this.amount),
      amountMinor: nextAmountMinor,
      currency: currency ?? this.currency,
      moneyVersion: nextMoneyVersion,
      rawAmount: nextRawAmount,
      isLegacyApproximate: isLegacyApproximate ?? this.isLegacyApproximate,
      hasMoneyInconsistency: hasMoneyInconsistency ?? this.hasMoneyInconsistency,
      categoryId: categoryId ?? this.categoryId,
      motivation: motivation ?? this.motivation,
      location: location ?? this.location,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      lastInstanceDate: lastInstanceDate ?? this.lastInstanceDate,
      isIncome: isIncome ?? this.isIncome,
      advanceGenerationCount:
          advanceGenerationCount ?? this.advanceGenerationCount,
      engineVersion: engineVersion ?? this.engineVersion,
      scheduleVersion: scheduleVersion ?? this.scheduleVersion,
      generationState: generationState ?? this.generationState,
      generationRevision: generationRevision ?? this.generationRevision,
      unmappedData: unmappedData ?? this.unmappedData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringExpense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          (amountMinor != null && other.amountMinor != null
              ? amountMinor == other.amountMinor
              : amount == other.amount) &&
          categoryId == other.categoryId &&
          motivation == other.motivation &&
          location == other.location &&
          frequency == other.frequency &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          dayOfWeek == other.dayOfWeek &&
          dayOfMonth == other.dayOfMonth &&
          monthOfYear == other.monthOfYear &&
          lastInstanceDate == other.lastInstanceDate &&
          isIncome == other.isIncome &&
          advanceGenerationCount == other.advanceGenerationCount &&
          engineVersion == other.engineVersion &&
          scheduleVersion == other.scheduleVersion &&
          generationState == other.generationState &&
          generationRevision == other.generationRevision;

  @override
  int get hashCode =>
      id.hashCode ^
      (amountMinor ?? amount).hashCode ^
      categoryId.hashCode ^
      motivation.hashCode ^
      location.hashCode ^
      frequency.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      dayOfWeek.hashCode ^
      dayOfMonth.hashCode ^
      monthOfYear.hashCode ^
      lastInstanceDate.hashCode ^
      isIncome.hashCode ^
      advanceGenerationCount.hashCode ^
      engineVersion.hashCode ^
      scheduleVersion.hashCode ^
      generationState.hashCode ^
      generationRevision.hashCode;
}
