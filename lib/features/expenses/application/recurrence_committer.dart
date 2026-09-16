import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/features/expenses/domain/recurrence_occurrence.dart';

enum RecurrenceCommitStatus { committed, conflict }

class RecurrenceCommitResult {
  final RecurrenceCommitStatus status;
  final String? message;

  const RecurrenceCommitResult._(this.status, {this.message});
  const RecurrenceCommitResult.committed()
    : this._(RecurrenceCommitStatus.committed);
  const RecurrenceCommitResult.conflict(String message)
    : this._(RecurrenceCommitStatus.conflict, message: message);

  bool get isCommitted => status == RecurrenceCommitStatus.committed;
}

/// Persists generated expenses, their ledger entries, and the rule cursor in
/// one Firestore transaction. This prevents partial recurrence generation.
class FirestoreRecurrenceCommitter {
  final FirebaseFirestore _firestore;

  FirestoreRecurrenceCommitter({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<RecurrenceCommitResult> commit({
    required String userId,
    required RecurringExpense rule,
    required DateTime? expectedCursor,
    required DateTime nextCursor,
    required List<Expense> expenses,
    required List<RecurrenceOccurrence> occurrences,
  }) async {
    if (rule.id == null || rule.id!.isEmpty) {
      return const RecurrenceCommitResult.conflict('A regra não possui ID.');
    }
    if (expenses.length != occurrences.length) {
      throw ArgumentError(
        'Cada despesa deve possuir uma ocorrência correspondente.',
      );
    }

    final user = _firestore.collection('users').doc(userId);
    final ruleRef = user.collection('recurring_expenses').doc(rule.id);
    final occurrenceCollection = user.collection('recurrence_occurrences');
    final expenseCollection = user.collection('expenses');

    return _firestore.runTransaction((transaction) async {
      final ruleSnapshot = await transaction.get(ruleRef);
      if (!ruleSnapshot.exists) {
        return const RecurrenceCommitResult.conflict(
          'A regra foi removida antes da geração ser confirmada.',
        );
      }

      final currentRule = RecurringExpense.fromMap(
        ruleSnapshot.data()!,
        ruleSnapshot.id,
      );
      if (!_sameInstant(currentRule.lastInstanceDate, expectedCursor)) {
        return const RecurrenceCommitResult.conflict(
          'A regra foi atualizada por outra sessão. Atualize a lista antes de gerar novamente.',
        );
      }
      if (currentRule.generationState == 'paused' ||
          currentRule.generationState == 'deleting') {
        return const RecurrenceCommitResult.conflict(
          'A regra não está disponível para geração.',
        );
      }

      for (var index = 0; index < occurrences.length; index++) {
        final occurrence = occurrences[index];
        final expenseId = expenses[index].id;
        if (expenseId == null || expenseId.isEmpty) {
          throw StateError('Despesa recorrente sem ID determinístico.');
        }
        final occurrenceSnapshot = await transaction.get(
          occurrenceCollection.doc(occurrence.occurrenceKey),
        );
        final expenseSnapshot = await transaction.get(
          expenseCollection.doc(expenseId),
        );
        if (occurrenceSnapshot.exists || expenseSnapshot.exists) {
          return const RecurrenceCommitResult.conflict(
            'Uma ocorrência concorrente já foi confirmada. Atualize a lista antes de gerar novamente.',
          );
        }
      }

      for (var index = 0; index < occurrences.length; index++) {
        final occurrence = occurrences[index];
        final expense = expenses[index];
        transaction.set(expenseCollection.doc(expense.id!), expense.toMap());
        transaction.set(
          occurrenceCollection.doc(occurrence.occurrenceKey),
          occurrence.toMap(),
        );
      }
      transaction.update(ruleRef, {
        'lastInstanceDate': Timestamp.fromDate(nextCursor),
        'generationState': 'ready',
        'engineVersion': 1,
        'scheduleVersion': currentRule.scheduleVersion ?? 1,
      });
      return const RecurrenceCommitResult.committed();
    });
  }

  static bool _sameInstant(DateTime? first, DateTime? second) {
    if (first == null || second == null) return first == second;
    return first.isAtSameMomentAs(second);
  }
}
