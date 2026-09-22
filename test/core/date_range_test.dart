import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/time/date_range.dart';

void main() {
  group('DateRange contract and acceptance tests', () {
    test('Leap year boundary acceptance: 01/02/2024 to 29/02/2024', () {
      final range = DateRange.fromDays(
        DateTime(2024, 2, 1),
        DateTime(2024, 2, 29),
      );

      expect(
        range.contains(DateTime(2024, 1, 31, 23, 59, 59, 999)),
        isFalse,
      );

      expect(
        range.contains(DateTime(2024, 2, 1, 0, 0, 0, 0)),
        isTrue,
      );

      expect(
        range.contains(DateTime(2024, 2, 29, 0, 0, 0, 0)),
        isTrue,
      );

      expect(
        range.contains(DateTime(2024, 2, 29, 12, 0, 0, 0)),
        isTrue,
      );

      expect(
        range.contains(DateTime(2024, 2, 29, 23, 59, 59, 999)),
        isTrue,
      );

      expect(
        range.contains(DateTime(2024, 3, 1, 0, 0, 0, 0)),
        isFalse,
      );
    });

    test('Non-leap year boundary: Feb 2023', () {
      final monthRange = DateRange.fromMonth(2023, 2);

      expect(monthRange.contains(DateTime(2023, 1, 31, 23, 59, 59, 999)), isFalse);
      expect(monthRange.contains(DateTime(2023, 2, 1, 0, 0, 0)), isTrue);
      expect(monthRange.contains(DateTime(2023, 2, 28, 23, 59, 59, 999)), isTrue);
      expect(monthRange.contains(DateTime(2023, 3, 1, 0, 0, 0)), isFalse);
    });

    test('Year turnover boundary: Dec 2023 to Jan 2024', () {
      final range = DateRange.fromDays(
        DateTime(2023, 12, 1),
        DateTime(2024, 1, 31),
      );

      expect(range.contains(DateTime(2023, 11, 30, 23, 59, 59, 999)), isFalse);
      expect(range.contains(DateTime(2023, 12, 1, 0, 0)), isTrue);
      expect(range.contains(DateTime(2023, 12, 31, 23, 59, 59, 999)), isTrue);
      expect(range.contains(DateTime(2024, 1, 1, 0, 0)), isTrue);
      expect(range.contains(DateTime(2024, 1, 31, 23, 59, 59, 999)), isTrue);
      expect(range.contains(DateTime(2024, 2, 1, 0, 0)), isFalse);
    });

    test('Single day interval [day at 00h, nextDay at 00h)', () {
      final singleDay = DateRange.singleDay(DateTime(2024, 5, 15));

      expect(singleDay.contains(DateTime(2024, 5, 14, 23, 59, 59)), isFalse);
      expect(singleDay.contains(DateTime(2024, 5, 15, 0, 0)), isTrue);
      expect(singleDay.contains(DateTime(2024, 5, 15, 12, 30)), isTrue);
      expect(singleDay.contains(DateTime(2024, 5, 15, 23, 59, 59, 999)), isTrue);
      expect(singleDay.contains(DateTime(2024, 5, 16, 0, 0)), isFalse);
      expect(singleDay.daysCount, 1);
    });

    test('Throws ArgumentError if start is after end', () {
      expect(
        () => DateRange.fromDays(DateTime(2024, 5, 20), DateTime(2024, 5, 10)),
        throwsArgumentError,
      );

      expect(
        () => DateRange(
          startInclusive: DateTime(2024, 5, 20),
          endExclusive: DateTime(2024, 5, 10),
        ),
        throwsArgumentError,
      );
    });

    test('Overlaps correctly detects range intersections', () {
      final r1 = DateRange.fromDays(DateTime(2024, 1, 1), DateTime(2024, 1, 10));
      final r2 = DateRange.fromDays(DateTime(2024, 1, 10), DateTime(2024, 1, 20));
      final r3 = DateRange.fromDays(DateTime(2024, 1, 11), DateTime(2024, 1, 20));

      expect(r1.overlaps(r2), isTrue);

      expect(r1.overlaps(r3), isFalse);
    });
  });
}
