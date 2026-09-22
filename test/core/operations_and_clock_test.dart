import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/core/operations/session_context.dart';
import 'package:key_budget/core/time/app_clock.dart';

void main() {
  group('AppClock', () {
    test('SystemAppClock returns current time', () {
      const clock = SystemAppClock();
      final before = DateTime.now();
      final now = clock.now();
      final after = DateTime.now();
      expect(now.isAfter(before) || now.isAtSameMomentAs(before), isTrue);
      expect(now.isBefore(after) || now.isAtSameMomentAs(after), isTrue);
    });

    test('TestAppClock allows freezing and advancing time', () {
      final initial = DateTime(2026, 9, 20, 10, 0, 0);
      final clock = TestAppClock(initial);
      expect(clock.now(), equals(initial));

      clock.advance(const Duration(hours: 2));
      expect(clock.now(), equals(DateTime(2026, 9, 20, 12, 0, 0)));

      final newTime = DateTime(2027, 1, 1);
      clock.set(newTime);
      expect(clock.now(), equals(newTime));
    });
  });

  group('SessionContext', () {
    test('validates user ID and session generation', () {
      const session = SessionContext(userId: 'user_1', sessionGeneration: 1);
      expect(session.isValidFor('user_1', 1), isTrue);
      expect(session.isValidFor('user_2', 1), isFalse);
      expect(session.isValidFor('user_1', 2), isFalse);
    });

    test('withOperation attaches operationId immutably', () {
      const session = SessionContext(userId: 'user_1', sessionGeneration: 1);
      final withOp = session.withOperation('op_123');
      expect(withOp.operationId, equals('op_123'));
      expect(session.operationId, isNull);
      expect(withOp.userId, equals('user_1'));
    });
  });

  group('OperationResult', () {
    test('completed factory sets correct status and counts', () {
      final res = OperationResult<String>.completed(
        data: 'success',
        affectedIds: ['id1', 'id2'],
        count: 2,
      );
      expect(res.isSuccess, isTrue);
      expect(res.status, equals(OperationStatus.completed));
      expect(res.data, equals('success'));
      expect(res.successCount, equals(2));
      expect(res.totalCount, equals(2));
    });

    test('partial factory sets correct counts and error', () {
      final res = OperationResult<void>.partial(
        totalCount: 5,
        successCount: 3,
        failedCount: 2,
        safeError: '2 falharam',
      );
      expect(res.isPartial, isTrue);
      expect(res.successCount, equals(3));
      expect(res.failedCount, equals(2));
      expect(res.safeError, equals('2 falharam'));
    });

    test('cancelled factory sets cancelled status', () {
      final res = OperationResult<void>.cancelled(message: 'Cancelado pelo usuário');
      expect(res.isCancelled, isTrue);
      expect(res.message, equals('Cancelado pelo usuário'));
    });

    test('failed factory records safe error without leaking raw data', () {
      final res = OperationResult<void>.failed(
        safeError: 'Falha de rede.',
        rawErrorCode: 'network_unavailable',
      );
      expect(res.isFailed, isTrue);
      expect(res.safeError, equals('Falha de rede.'));
      expect(res.rawErrorCode, equals('network_unavailable'));
    });

    test('conflict factory records affected conflicting IDs', () {
      final res = OperationResult<void>.conflict(
        message: 'Versão concorrente detectada',
        affectedIds: ['doc_1'],
      );
      expect(res.isConflict, isTrue);
      expect(res.conflictCount, equals(1));
      expect(res.affectedIds, contains('doc_1'));
    });
  });
}
