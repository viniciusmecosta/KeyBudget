import 'package:flutter/foundation.dart';

@immutable
class DateRange {
  final DateTime startInclusive;
  final DateTime endExclusive;

  const DateRange._({
    required this.startInclusive,
    required this.endExclusive,
  });

  factory DateRange({
    required DateTime startInclusive,
    required DateTime endExclusive,
  }) {
    if (startInclusive.isAfter(endExclusive)) {
      throw ArgumentError(
        'startInclusive ($startInclusive) cannot be after endExclusive ($endExclusive)',
      );
    }
    return DateRange._(
      startInclusive: startInclusive,
      endExclusive: endExclusive,
    );
  }

  factory DateRange.fromMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return DateRange._(startInclusive: start, endExclusive: end);
  }

  factory DateRange.fromDays(DateTime startDay, DateTime endDay) {
    final startCivil = DateTime(startDay.year, startDay.month, startDay.day);
    final endCivil = DateTime(endDay.year, endDay.month, endDay.day);
    if (startCivil.isAfter(endCivil)) {
      throw ArgumentError(
        'startDay ($startDay) cannot be after endDay ($endDay)',
      );
    }
    final nextDayAfterEnd =
        DateTime(endCivil.year, endCivil.month, endCivil.day + 1);
    return DateRange._(
      startInclusive: startCivil,
      endExclusive: nextDayAfterEnd,
    );
  }

  factory DateRange.singleDay(DateTime day) {
    return DateRange.fromDays(day, day);
  }

  bool contains(DateTime date) {
    final isAfterOrEqualStart =
        date.isAfter(startInclusive) || date.isAtSameMomentAs(startInclusive);
    final isBeforeEnd = date.isBefore(endExclusive);
    return isAfterOrEqualStart && isBeforeEnd;
  }

  bool overlaps(DateRange other) {
    return startInclusive.isBefore(other.endExclusive) &&
        endExclusive.isAfter(other.startInclusive);
  }

  Duration get duration => endExclusive.difference(startInclusive);

  int get daysCount {
    return (endExclusive.difference(startInclusive).inHours / 24).round();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startInclusive.isAtSameMomentAs(other.startInclusive) &&
          endExclusive.isAtSameMomentAs(other.endExclusive);

  @override
  int get hashCode => Object.hash(startInclusive, endExclusive);

  @override
  String toString() => 'DateRange([$startInclusive, $endExclusive))';
}
