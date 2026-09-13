import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/money/money.dart';

class InstallmentCalculationResult {
  final String groupId;
  final Money totalAmount;
  final int count;
  final List<Expense> expenses;

  const InstallmentCalculationResult({
    required this.groupId,
    required this.totalAmount,
    required this.count,
    required this.expenses,
  });

  int get sumOfCents =>
      expenses.fold(0, (acc, e) => acc + (e.amountMinor ?? e.money.amountMinor));
}

class InstallmentCalculator {

  static InstallmentCalculationResult calculate({
    required Expense baseExpense,
    required int count,
    required bool startNextMonth,
    String? operationId,
  }) {
    if (count < 1) {
      throw ArgumentError('O número de parcelas deve ser maior ou igual a 1 (recebido: $count).');
    }

    if (baseExpense.isIncome == true) {
      throw ArgumentError('Parcelamento não é permitido para receitas (isIncome == true).');
    }

    final totalMoney = baseExpense.money;
    final totalCents = totalMoney.amountMinor;

    if (totalCents < 0) {
      throw ArgumentError('O valor total não pode ser negativo para parcelamento ($totalCents centavos).');
    }

    if (totalCents > 0 && count > totalCents) {
      throw ArgumentError(
        'Número de parcelas ($count) não pode exceder o total em centavos ($totalCents), '
        'pois geraria parcelas de zero centavos.',
      );
    }

    final baseCents = count > 0 ? totalCents ~/ count : 0;
    final remainder = count > 0 ? totalCents % count : 0;

    final groupId = operationId ?? 'grp_${DateTime.now().millisecondsSinceEpoch}';
    final List<Expense> expenses = [];
    final monthOffset = startNextMonth ? 1 : 0;
    final anchorDay = baseExpense.date.day;

    for (int i = 0; i < count; i++) {
      final installmentNumber = i + 1;
      final installmentCents = baseCents + (i < remainder ? 1 : 0);
      final installmentMoney = Money.fromCents(
        installmentCents,
        currency: totalMoney.currency,
      );

      int targetYear = baseExpense.date.year;
      int targetMonth = baseExpense.date.month + monthOffset + i;
      while (targetMonth > 12) {
        targetMonth -= 12;
        targetYear += 1;
      }
      final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
      final finalDay = anchorDay > daysInTargetMonth ? daysInTargetMonth : anchorDay;
      final installmentDate = DateTime(
        targetYear,
        targetMonth,
        finalDay,
        baseExpense.date.hour,
        baseExpense.date.minute,
        baseExpense.date.second,
      );

      final baseMotivation = baseExpense.motivation?.trim() ?? '';
      final motivation = baseMotivation.isNotEmpty
          ? '$baseMotivation ($installmentNumber/$count)'
          : 'Parcela $installmentNumber/$count';

      final stableId = '${groupId}_$installmentNumber';

      expenses.add(
        Expense(
          id: stableId,
          amount: installmentMoney.toDouble(),
          amountMinor: installmentMoney.amountMinor,
          currency: installmentMoney.currency,
          moneyVersion: 1,
          rawAmount: installmentMoney.toDouble(),
          date: installmentDate,
          categoryId: baseExpense.categoryId,
          motivation: motivation,
          location: baseExpense.location,
          installmentGroupId: groupId,
          currentInstallment: installmentNumber,
          totalInstallments: count,
          isIncome: baseExpense.isIncome ?? false,
          recurringExpenseId: baseExpense.recurringExpenseId,
          unmappedData: Map.from(baseExpense.unmappedData),
        ),
      );
    }

    return InstallmentCalculationResult(
      groupId: groupId,
      totalAmount: totalMoney,
      count: count,
      expenses: expenses,
    );
  }
}
