import 'package:key_budget/core/models/recurring_expense_model.dart';

class RecurrenceSchedule {

  static DateTime? getNextCandidateDate({
    required RecurringExpense rule,
    DateTime? cursor,
    int? overrideScheduleVersion,
  }) {
    if (cursor == null) {
      return rule.startDate;
    }

    final effectiveVersion =
        overrideScheduleVersion ?? rule.scheduleVersion ?? 0;
    final isLegacy = effectiveVersion == 0;

    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        if (isLegacy) {

          return cursor.add(const Duration(days: 1));
        } else {

          return DateTime(
            cursor.year,
            cursor.month,
            cursor.day + 1,
            rule.startDate.hour,
            rule.startDate.minute,
            rule.startDate.second,
          );
        }

      case RecurrenceFrequency.weekly:
        if (isLegacy) {

          return cursor.add(const Duration(days: 7));
        } else {

          return DateTime(
            cursor.year,
            cursor.month,
            cursor.day + 7,
            rule.startDate.hour,
            rule.startDate.minute,
            rule.startDate.second,
          );
        }

      case RecurrenceFrequency.monthly:
        int nextYear = cursor.year;
        int nextMonth = cursor.month + 1;
        while (nextMonth > 12) {
          nextMonth -= 12;
          nextYear += 1;
        }

        final int targetDay;
        if (isLegacy) {

          final baseDay = rule.dayOfMonth ?? cursor.day;
          final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
          targetDay = baseDay > maxDay ? maxDay : baseDay;
        } else {

          final anchorDay = rule.dayOfMonth ?? rule.startDate.day;
          final maxDay = DateTime(nextYear, nextMonth + 1, 0).day;
          targetDay = anchorDay > maxDay ? maxDay : anchorDay;
        }

        return DateTime(
          nextYear,
          nextMonth,
          targetDay,
          rule.startDate.hour,
          rule.startDate.minute,
          rule.startDate.second,
        );
    }
  }

  static DateTime getTargetHorizonDate(
    DateTime now,
    RecurringExpense rule,
  ) {
    final count = rule.advanceGenerationCount;
    if (count <= 0) {
      return now;
    }

    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return now.add(Duration(days: count));

      case RecurrenceFrequency.weekly:
        return now.add(Duration(days: 7 * count));

      case RecurrenceFrequency.monthly:

        int targetYear = now.year;
        int targetMonth = now.month + count;
        while (targetMonth > 12) {
          targetMonth -= 12;
          targetYear += 1;
        }

        final firstOfNext = DateTime(targetYear, targetMonth + 1, 1);
        return firstOfNext.subtract(const Duration(milliseconds: 1));
    }
  }

  static bool isPastEndDate(
    DateTime candidate,
    DateTime? endDate, {
    int? scheduleVersion,
  }) {
    if (endDate == null) return false;

    final version = scheduleVersion ?? 1;
    if (version == 0) {
      return candidate.isAfter(endDate);
    } else {

      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
      return candidate.isAfter(endOfDay);
    }
  }
}
