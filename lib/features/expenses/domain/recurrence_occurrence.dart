import 'dart:convert';
import 'package:crypto/crypto.dart';

enum OccurrenceState {

  materialized,

  suppressed,
}

class RecurrenceOccurrence {
  final String occurrenceKey;
  final String recurringExpenseId;
  final String scheduledDateKey;
  final DateTime? scheduledDateOriginal;
  final List<String> expenseIds;
  final OccurrenceState state;
  final int engineVersion;
  final String? operationId;

  const RecurrenceOccurrence({
    required this.occurrenceKey,
    required this.recurringExpenseId,
    required this.scheduledDateKey,
    this.scheduledDateOriginal,
    this.expenseIds = const [],
    this.state = OccurrenceState.materialized,
    this.engineVersion = 1,
    this.operationId,
  });

  static String generateKey({
    required String uid,
    required String recurringExpenseId,
    required String scheduledDateKey,
  }) {
    final payload =
        '["keybudget","$uid","$recurringExpenseId","$scheduledDateKey"]';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String get deterministicExpenseId => 'rec_$occurrenceKey';

  Map<String, dynamic> toMap() => {
        'recurringExpenseId': recurringExpenseId,
        'scheduledDateKey': scheduledDateKey,
        'scheduledDateOriginal': scheduledDateOriginal?.toIso8601String(),
        'expenseIds': expenseIds,
        'state': state.name,
        'engineVersion': engineVersion,
        'operationId': operationId,
      };

  factory RecurrenceOccurrence.fromMap(Map<String, dynamic> map, String key) {
    final dateStr = map['scheduledDateOriginal'] as String?;
    final idsRaw = map['expenseIds'] as List<dynamic>? ?? [];
    return RecurrenceOccurrence(
      occurrenceKey: key,
      recurringExpenseId: map['recurringExpenseId'] as String? ?? '',
      scheduledDateKey: map['scheduledDateKey'] as String? ?? '',
      scheduledDateOriginal: dateStr != null ? DateTime.parse(dateStr) : null,
      expenseIds: idsRaw.map((e) => e.toString()).toList(),
      state: (map['state'] as String?) == 'suppressed'
          ? OccurrenceState.suppressed
          : OccurrenceState.materialized,
      engineVersion: (map['engineVersion'] as int?) ?? 1,
      operationId: map['operationId'] as String?,
    );
  }

  RecurrenceOccurrence copyWith({
    String? occurrenceKey,
    String? recurringExpenseId,
    String? scheduledDateKey,
    DateTime? scheduledDateOriginal,
    List<String>? expenseIds,
    OccurrenceState? state,
    int? engineVersion,
    String? operationId,
  }) {
    return RecurrenceOccurrence(
      occurrenceKey: occurrenceKey ?? this.occurrenceKey,
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
      scheduledDateKey: scheduledDateKey ?? this.scheduledDateKey,
      scheduledDateOriginal:
          scheduledDateOriginal ?? this.scheduledDateOriginal,
      expenseIds: expenseIds ?? this.expenseIds,
      state: state ?? this.state,
      engineVersion: engineVersion ?? this.engineVersion,
      operationId: operationId ?? this.operationId,
    );
  }
}
