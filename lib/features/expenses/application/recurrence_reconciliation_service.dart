import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/features/expenses/domain/recurrence_occurrence.dart';
import 'package:key_budget/features/expenses/repository/recurrence_occurrence_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';

class RecurrenceReconciliationReport {
  final String ruleId;
  final int totalLinkedExpenses;
  final List<List<String>> duplicateGroups;
  final List<String> gapDates;
  final bool hasExtraPrecision;
  final bool hasOrphanDates;
  final String suggestedState;
  final String summary;

  const RecurrenceReconciliationReport({
    required this.ruleId,
    required this.totalLinkedExpenses,
    this.duplicateGroups = const [],
    this.gapDates = const [],
    this.hasExtraPrecision = false,
    this.hasOrphanDates = false,
    required this.suggestedState,
    required this.summary,
  });

  bool get hasDuplicates => duplicateGroups.isNotEmpty;
  bool get hasIssues =>
      hasDuplicates || hasExtraPrecision || hasOrphanDates;
  bool get isSafeToGenerate => suggestedState == 'ready';
}

class RecurrenceReconciliationService {
  final RecurringExpenseRepository recurringRepository;
  final RecurrenceOccurrenceRepository occurrenceRepository;

  RecurrenceReconciliationService({
    required this.recurringRepository,
    required this.occurrenceRepository,
  });

  RecurrenceReconciliationReport simulateRule({
    required RecurringExpense rule,
    required List<Expense> linkedExpenses,
  }) {
    final ruleId = rule.id ?? 'unknown_rule';

    final Map<String, List<Expense>> expensesByDay = {};
    bool extraPrecision = Money.hasMoreThanTwoDecimals(rule.amount);

    for (final exp in linkedExpenses) {
      if (Money.hasMoreThanTwoDecimals(exp.amount)) {
        extraPrecision = true;
      }
      final key = RecurrenceOccurrence.formatDateKey(exp.date);
      expensesByDay.putIfAbsent(key, () => []).add(exp);
    }

    final List<List<String>> duplicates = [];
    for (final entry in expensesByDay.entries) {
      if (entry.value.length > 1) {
        duplicates.add(entry.value.map((e) => e.id ?? '').toList());
      }
    }

    bool orphanOrPastCursor = false;
    if (rule.lastInstanceDate != null) {
      final cursorKey =
          RecurrenceOccurrence.formatDateKey(rule.lastInstanceDate!);
      for (final key in expensesByDay.keys) {
        if (key.compareTo(cursorKey) > 0) {
          orphanOrPastCursor = true;
          break;
        }
      }
    }

    final bool shouldPause = duplicates.isNotEmpty || extraPrecision;
    final suggestedState = shouldPause ? 'paused' : 'ready';

    final buffer = StringBuffer();
    if (duplicates.isNotEmpty) {
      buffer.write('${duplicates.length} duplicatas detectadas. ');
    }
    if (extraPrecision) {
      buffer.write('Valores com mais de duas casas decimais presentes. ');
    }
    if (buffer.isEmpty) {
      buffer.write('Regra consistente. Pronta para geração controlada.');
    }

    return RecurrenceReconciliationReport(
      ruleId: ruleId,
      totalLinkedExpenses: linkedExpenses.length,
      duplicateGroups: duplicates,
      hasExtraPrecision: extraPrecision,
      hasOrphanDates: orphanOrPastCursor,
      suggestedState: suggestedState,
      summary: buffer.toString().trim(),
    );
  }

  Future<OperationResult<void>> reconcileRule({
    required String userId,
    required RecurringExpense rule,
    required List<Expense> linkedExpenses,
  }) async {
    try {
      final report = simulateRule(
        rule: rule,
        linkedExpenses: linkedExpenses,
      );

      if (report.hasDuplicates && rule.generationState != 'ready') {
        final pausedRule = rule.copyWith(generationState: 'paused');
        await recurringRepository.updateRecurringExpense(userId, pausedRule);
        return OperationResult.conflict(
          message:
              'Regra pausada para resolução de conflitos: ${report.summary}',
          affectedIds: report.duplicateGroups.expand((g) => g).toList(),
        );
      }

      final Map<String, List<String>> dateToExpenseIds = {};
      for (final exp in linkedExpenses) {
        final key = RecurrenceOccurrence.formatDateKey(exp.date);
        dateToExpenseIds
            .putIfAbsent(key, () => [])
            .add(exp.id ?? 'unknown_${exp.date.millisecondsSinceEpoch}');
      }

      final List<RecurrenceOccurrence> ledgerEntries = [];
      for (final entry in dateToExpenseIds.entries) {
        final dateKey = entry.key;
        final occurrenceKey = RecurrenceOccurrence.generateKey(
          uid: userId,
          recurringExpenseId: rule.id!,
          scheduledDateKey: dateKey,
        );

        ledgerEntries.add(
          RecurrenceOccurrence(
            occurrenceKey: occurrenceKey,
            recurringExpenseId: rule.id!,
            scheduledDateKey: dateKey,
            expenseIds: entry.value,
            state: OccurrenceState.materialized,
            engineVersion: 1,
          ),
        );
      }

      if (ledgerEntries.isNotEmpty) {
        await occurrenceRepository.saveOccurrencesBatch(
          userId,
          ledgerEntries,
        );
      }

      final updatedRule = rule.copyWith(
        generationState: 'ready',
        engineVersion: 1,
        scheduleVersion: rule.scheduleVersion ?? 1,
      );
      await recurringRepository.updateRecurringExpense(userId, updatedRule);

      return OperationResult.completed(count: ledgerEntries.length);
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Não foi possível atualizar a recorrência. Tente novamente.',
      );
    }
  }
}
