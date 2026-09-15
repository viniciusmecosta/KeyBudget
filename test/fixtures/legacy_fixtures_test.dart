import 'package:flutter_test/flutter_test.dart';
import 'legacy/legacy_fixtures.dart';

void main() {
  group('SyntheticTimestamp', () {
    test('round-trip conversion to DateTime preserves timestamp integrity', () {
      final now = DateTime(2026, 9, 20, 15, 30, 45, 123);
      final synth = SyntheticTimestamp.fromDate(now);
      expect(synth.toDate().millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));

      final map = synth.toMap();
      final fromMap = SyntheticTimestamp.fromMap(map);
      expect(fromMap.seconds, equals(synth.seconds));
      expect(fromMap.nanoseconds, equals(synth.nanoseconds));
    });
  });

  group('LegacyFixtures L01 to L16 completeness', () {
    test('L01 to L16 are all populated with expected structure', () {
      expect(LegacyFixtures.l01['id'], equals('L01'));
      expect(LegacyFixtures.l02['id'], equals('L02'));
      expect(LegacyFixtures.l03['id'], equals('L03'));
      expect(LegacyFixtures.l04['id'], equals('L04'));
      expect(LegacyFixtures.l05['id'], equals('L05'));
      expect(LegacyFixtures.l06['id'], equals('L06'));
      expect(LegacyFixtures.l07['id'], equals('L07'));
      expect(LegacyFixtures.l08['id'], equals('L08'));
      expect(LegacyFixtures.l09['id'], equals('L09'));
      expect(LegacyFixtures.l10['id'], equals('L10'));
      expect(LegacyFixtures.l11['id'], equals('L11'));
      expect(LegacyFixtures.l12['id'], equals('L12'));
      expect(LegacyFixtures.l13['id'], equals('L13'));
      expect(LegacyFixtures.l14['id'], equals('L14'));
      expect(LegacyFixtures.l15['id'], equals('L15'));
      expect(LegacyFixtures.l16['id'], equals('L16'));
    });
  });
}
