import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:key_budget/features/expenses/application/recurrence_committer.dart';
import 'package:key_budget/features/expenses/domain/recurrence_occurrence.dart';
import 'package:key_budget/features/expenses/domain/recurrence_schedule.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/repository/recurrence_occurrence_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';

class RecurrenceService {
  final ExpenseRepository expenseRepository;
  final RecurringExpenseRepository recurringRepository;
  final RecurrenceOccurrenceRepository occurrenceRepository;
  final AppClock clock;
  final FirestoreRecurrenceCommitter? committer;

  RecurrenceService({
    required this.expenseRepository,
    required this.recurringRepository,
    required this.occurrenceRepository,
    this.clock = const SystemAppClock(),
    this.committer,
  });

  Future<OperationResult<List<Expense>>> generatePendingOccurrences(
    String userId, {
    List<RecurringExpense>? rulesToProcess,
    int maxOccurrencesPerRule = 60,
  }) async {
    try {
      final now = clock.now();
      final allRules =
          rulesToProcess ??
          await recurringRepository.getRecurringExpensesStream(userId).first;

      final List<Expense> allCreatedExpenses = [];

      for (final rule in allRules) {
        if (rule.id == null || rule.id!.isEmpty) continue;

        if (rule.generationState == 'paused' ||
            rule.generationState == 'deleting') {
          continue;
        }

        final targetHorizon = RecurrenceSchedule.getTargetHorizonDate(
          now,
          rule,
        );

        if (rule.lastInstanceDate != null &&
            rule.lastInstanceDate!.isAfter(targetHorizon)) {
          continue;
        }

        DateTime? cursor = rule.lastInstanceDate;
        final List<Expense> toAddExpenses = [];
        final List<RecurrenceOccurrence> toAddOccurrences = [];
        int iterations = 0;

        while (iterations < maxOccurrencesPerRule) {
          iterations++;

          final candidateDate = RecurrenceSchedule.getNextCandidateDate(
            rule: rule,
            cursor: cursor,
          );

          if (candidateDate == null ||
              candidateDate.isAfter(targetHorizon) ||
              RecurrenceSchedule.isPastEndDate(
                candidateDate,
                rule.endDate,
                scheduleVersion: rule.scheduleVersion,
              )) {
            break;
          }

          final dateKey = RecurrenceOccurrence.formatDateKey(candidateDate);
          final occurrenceKey = RecurrenceOccurrence.generateKey(
            uid: userId,
            recurringExpenseId: rule.id!,
            scheduledDateKey: dateKey,
          );

          final existingOccurrence = await occurrenceRepository.getOccurrence(
            userId,
            occurrenceKey,
          );

          if (existingOccurrence != null) {
            cursor = candidateDate;
            continue;
          }

          final occurrence = RecurrenceOccurrence(
            occurrenceKey: occurrenceKey,
            recurringExpenseId: rule.id!,
            scheduledDateKey: dateKey,
            scheduledDateOriginal: candidateDate,
            expenseIds: ['rec_$occurrenceKey'],
            state: OccurrenceState.materialized,
            engineVersion: 1,
          );

          final newExpense = Expense.withMoney(
            id: 'rec_$occurrenceKey',
            money: rule.money,
            date: candidateDate,
            categoryId: rule.categoryId,
            motivation: rule.motivation,
            location: rule.location,
            isIncome: rule.isIncome ?? false,
            recurringExpenseId: rule.id,
            occurrenceKey: occurrenceKey,
            scheduledDateKey: dateKey,
          );

          toAddExpenses.add(newExpense);
          toAddOccurrences.add(occurrence);
          cursor = candidateDate;
        }

        if (cursor != null && cursor != rule.lastInstanceDate) {
          if (committer != null) {
            final commit = await committer!.commit(
              userId: userId,
              rule: rule,
              expectedCursor: rule.lastInstanceDate,
              nextCursor: cursor,
              expenses: toAddExpenses,
              occurrences: toAddOccurrences,
            );
            if (!commit.isCommitted) {
              return OperationResult.conflict(
                message:
                    commit.message ??
                    'A regra mudou durante a geração. Atualize e tente novamente.',
                affectedIds: [rule.id!],
              );
            }
            allCreatedExpenses.addAll(toAddExpenses);
          } else {
            if (toAddExpenses.isNotEmpty) {
              await expenseRepository.addExpensesBatch(userId, toAddExpenses);
              await occurrenceRepository.saveOccurrencesBatch(
                userId,
                toAddOccurrences,
              );
              allCreatedExpenses.addAll(toAddExpenses);
            }
            final updatedRule = rule.copyWith(
              lastInstanceDate: cursor,
              generationState: 'ready',
              engineVersion: 1,
              scheduleVersion: rule.scheduleVersion ?? 1,
            );
            await recurringRepository.updateRecurringExpense(
              userId,
              updatedRule,
            );
          }
        }
      }

      return OperationResult.completed(
        data: allCreatedExpenses,
        count: allCreatedExpenses.length,
        affectedIds: allCreatedExpenses.map((e) => e.id ?? '').toList(),
      );
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Não foi possível gerar as despesas recorrentes. Tente novamente.',
      );
    }
  }
}
