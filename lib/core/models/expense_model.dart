import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/money/money.dart';

class Expense {
  final String? id;
  final double amount;
  final int? amountMinor;
  final String? currency;
  final int? moneyVersion;
  final num? rawAmount;
  final bool isLegacyApproximate;
  final bool hasMoneyInconsistency;
  final DateTime date;
  final String? categoryId;
  final String? motivation;
  final String? location;
  final String? installmentGroupId;
  final int? currentInstallment;
  final int? totalInstallments;
  final bool? isIncome;
  final String? recurringExpenseId;
  final String? occurrenceKey;
  final String? scheduledDateKey;
  final Map<String, dynamic> unmappedData;

  Expense({
    this.id,
    required this.amount,
    this.amountMinor,
    this.currency,
    this.moneyVersion,
    this.rawAmount,
    this.isLegacyApproximate = false,
    this.hasMoneyInconsistency = false,
    required this.date,
    this.categoryId,
    this.motivation,
    this.location,
    this.installmentGroupId,
    this.currentInstallment,
    this.totalInstallments,
    this.isIncome,
    this.recurringExpenseId,
    this.occurrenceKey,
    this.scheduledDateKey,
    Map<String, dynamic>? unmappedData,
  }) : unmappedData = unmappedData != null
            ? Map.unmodifiable(unmappedData)
            : const {};

  factory Expense.withMoney({
    String? id,
    required Money money,
    required DateTime date,
    String? categoryId,
    String? motivation,
    String? location,
    String? installmentGroupId,
    int? currentInstallment,
    int? totalInstallments,
    bool? isIncome,
    String? recurringExpenseId,
    String? occurrenceKey,
    String? scheduledDateKey,
    Map<String, dynamic>? unmappedData,
  }) {
    return Expense(
      id: id,
      amount: money.toDouble(),
      amountMinor: money.amountMinor,
      currency: money.currency,
      moneyVersion: 1,
      rawAmount: money.toDouble(),
      date: date,
      categoryId: categoryId,
      motivation: motivation,
      location: location,
      installmentGroupId: installmentGroupId,
      currentInstallment: currentInstallment,
      totalInstallments: totalInstallments,
      isIncome: isIncome,
      recurringExpenseId: recurringExpenseId,
      occurrenceKey: occurrenceKey,
      scheduledDateKey: scheduledDateKey,
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
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'motivation': motivation,
      'location': location,
      'installmentGroupId': installmentGroupId,
      'currentInstallment': currentInstallment,
      'totalInstallments': totalInstallments,
      'isIncome': isIncome,
      'recurringExpenseId': recurringExpenseId,
      'occurrenceKey': occurrenceKey,
      'scheduledDateKey': scheduledDateKey,
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

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    final rawAmountVal = map['amount'];
    if (rawAmountVal == null) {
      throw FormatException('O campo amount é obrigatório para Expense $id');
    }
    if (rawAmountVal is! num) {
      throw FormatException('O campo amount deve ser numérico para Expense $id');
    }
    if (rawAmountVal.isNaN || rawAmountVal.isInfinite) {
      throw FormatException('O campo amount não pode ser NaN ou infinito para Expense $id');
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
      'date',
      'categoryId',
      'motivation',
      'location',
      'installmentGroupId',
      'currentInstallment',
      'totalInstallments',
      'isIncome',
      'recurringExpenseId',
      'occurrenceKey',
      'scheduledDateKey',
    };
    final unmapped = <String, dynamic>{};
    map.forEach((k, v) {
      if (!knownKeys.contains(k)) {
        unmapped[k] = v;
      }
    });

    final dateVal = map['date'];
    final DateTime parsedDate;
    if (dateVal is String) {
      parsedDate = DateTime.parse(dateVal);
    } else if (dateVal is DateTime) {
      parsedDate = dateVal;
    } else if (dateVal is Timestamp) {
      parsedDate = dateVal.toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return Expense(
      id: id,
      amount: rawAmount.toDouble(),
      amountMinor: effectiveAmountMinor,
      currency: currency,
      moneyVersion: moneyVersion,
      rawAmount: rawAmount,
      isLegacyApproximate: isApprox,
      hasMoneyInconsistency: hasInconsistency,
      date: parsedDate,
      categoryId: map['categoryId'],
      motivation: map['motivation'],
      location: map['location'],
      installmentGroupId: map['installmentGroupId'],
      currentInstallment: map['currentInstallment'] as int?,
      totalInstallments: map['totalInstallments'] as int?,
      isIncome: map['isIncome'] as bool?,
      recurringExpenseId: map['recurringExpenseId'],
      occurrenceKey: map['occurrenceKey'] as String?,
      scheduledDateKey: map['scheduledDateKey'] as String?,
      unmappedData: unmapped,
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    int? amountMinor,
    String? currency,
    int? moneyVersion,
    num? rawAmount,
    bool? isLegacyApproximate,
    bool? hasMoneyInconsistency,
    DateTime? date,
    String? categoryId,
    String? motivation,
    String? location,
    String? installmentGroupId,
    int? currentInstallment,
    int? totalInstallments,
    bool? isIncome,
    String? recurringExpenseId,
    String? occurrenceKey,
    String? scheduledDateKey,
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

    return Expense(
      id: id ?? this.id,
      amount: amount ??
          (amountMinor != null ? amountMinor / 100.0 : this.amount),
      amountMinor: nextAmountMinor,
      currency: currency ?? this.currency,
      moneyVersion: nextMoneyVersion,
      rawAmount: nextRawAmount,
      isLegacyApproximate: isLegacyApproximate ?? this.isLegacyApproximate,
      hasMoneyInconsistency: hasMoneyInconsistency ?? this.hasMoneyInconsistency,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      motivation: motivation ?? this.motivation,
      location: location ?? this.location,
      installmentGroupId: installmentGroupId ?? this.installmentGroupId,
      currentInstallment: currentInstallment ?? this.currentInstallment,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      isIncome: isIncome ?? this.isIncome,
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
      occurrenceKey: occurrenceKey ?? this.occurrenceKey,
      scheduledDateKey: scheduledDateKey ?? this.scheduledDateKey,
      unmappedData: unmappedData ?? this.unmappedData,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          (amountMinor != null && other.amountMinor != null
              ? amountMinor == other.amountMinor
              : amount == other.amount) &&
          date == other.date &&
          categoryId == other.categoryId &&
          motivation == other.motivation &&
          location == other.location &&
          installmentGroupId == other.installmentGroupId &&
          currentInstallment == other.currentInstallment &&
          totalInstallments == other.totalInstallments &&
          isIncome == other.isIncome &&
          recurringExpenseId == other.recurringExpenseId &&
          occurrenceKey == other.occurrenceKey &&
          scheduledDateKey == other.scheduledDateKey;

  @override
  int get hashCode =>
      id.hashCode ^
      (amountMinor ?? amount).hashCode ^
      date.hashCode ^
      categoryId.hashCode ^
      motivation.hashCode ^
      location.hashCode ^
      installmentGroupId.hashCode ^
      currentInstallment.hashCode ^
      totalInstallments.hashCode ^
      isIncome.hashCode ^
      recurringExpenseId.hashCode ^
      occurrenceKey.hashCode ^
      scheduledDateKey.hashCode;
}
