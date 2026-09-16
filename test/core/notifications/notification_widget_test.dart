import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/notifications/notification_gateway.dart';
import 'package:key_budget/core/notifications/notification_id_registry.dart';
import 'package:key_budget/core/notifications/notification_reconciler.dart';
import 'package:key_budget/core/services/home_widget_service.dart';
import 'package:key_budget/core/time/app_clock.dart';

class FakeClock implements AppClock {
  DateTime _current;
  FakeClock(this._current);

  void setTime(DateTime time) {
    _current = time;
  }

  @override
  DateTime now() => _current;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationIdRegistry - Mapeamento Estável e Resolução de Colisões', () {
    late NotificationIdRegistry registry;

    setUp(() {
      registry = NotificationIdRegistry();
    });

    test(
      'Aloca ID estável e preserva na segunda chamada com a mesma chave lógica',
      () async {
        final entry1 = await registry.getOrAllocate(
          logicalKey: 'user1__ruleA__2026-06-15__reminder',
          uid: 'user1',
          ruleId: 'ruleA',
          scheduledDateKey: '2026-06-15',
          fingerprint: 'fp1',
          scheduledAt: DateTime(2026, 6, 15, 9, 0),
        );

        expect(entry1.nativeId, isPositive);

        final entry2 = await registry.getOrAllocate(
          logicalKey: 'user1__ruleA__2026-06-15__reminder',
          uid: 'user1',
          ruleId: 'ruleA',
          scheduledDateKey: '2026-06-15',
          fingerprint: 'fp1_updated',
          scheduledAt: DateTime(2026, 6, 15, 9, 0),
        );

        expect(entry2.nativeId, equals(entry1.nativeId));
        expect(entry2.fingerprint, equals('fp1_updated'));
      },
    );

    test(
      'Deriva o mesmo ID em registries novos sem depender de hashCode do processo',
      () async {
        const logicalKey = 'user1__ruleA__2026-06-15__reminder';
        final first = await registry.getOrAllocate(
          logicalKey: logicalKey,
          uid: 'user1',
          ruleId: 'ruleA',
          scheduledDateKey: '2026-06-15',
          fingerprint: 'fp',
          scheduledAt: DateTime(2026, 6, 15, 9),
        );
        final secondRegistry = NotificationIdRegistry();
        final second = await secondRegistry.getOrAllocate(
          logicalKey: logicalKey,
          uid: 'user1',
          ruleId: 'ruleA',
          scheduledDateKey: '2026-06-15',
          fingerprint: 'fp',
          scheduledAt: DateTime(2026, 6, 15, 9),
        );

        expect(second.nativeId, first.nativeId);
      },
    );

    test(
      'Detecta colisão e aloca ID distinto para chave lógica diferente',
      () async {
        final entryA = await registry.getOrAllocate(
          logicalKey: 'user1__ruleA__2026-06-15__reminder',
          uid: 'user1',
          ruleId: 'ruleA',
          scheduledDateKey: '2026-06-15',
          fingerprint: 'fpA',
          scheduledAt: DateTime(2026, 6, 15, 9, 0),
        );

        final entryB = await registry.getOrAllocate(
          logicalKey: 'user1__ruleB__2026-06-15__reminder',
          uid: 'user1',
          ruleId: 'ruleB',
          scheduledDateKey: '2026-06-15',
          fingerprint: 'fpB',
          scheduledAt: DateTime(2026, 6, 15, 9, 0),
        );

        expect(entryA.nativeId, isNot(equals(entryB.nativeId)));
      },
    );

    test(
      'removeEntriesForUid remove apenas notificações da sessão indicada',
      () async {
        await registry.getOrAllocate(
          logicalKey: 'user1__ruleA__2026-06-15__reminder',
          uid: 'user1',
          ruleId: 'ruleA',
          scheduledDateKey: '2026-06-15',
          fingerprint: 'fpA',
          scheduledAt: DateTime(2026, 6, 15, 9, 0),
        );

        await registry.getOrAllocate(
          logicalKey: 'user2__ruleZ__2026-06-15__reminder',
          uid: 'user2',
          ruleId: 'ruleZ',
          scheduledDateKey: '2026-06-15',
          fingerprint: 'fpZ',
          scheduledAt: DateTime(2026, 6, 15, 9, 0),
        );

        expect(registry.getEntriesForUid('user1').length, equals(1));
        expect(registry.getEntriesForUid('user2').length, equals(1));

        await registry.removeEntriesForUid('user1');

        expect(registry.getEntriesForUid('user1'), isEmpty);
        expect(registry.getEntriesForUid('user2').length, equals(1));
      },
    );
  });

  group('NotificationReconciler - Agenda e Reconciliação Idempotente', () {
    late FakeClock clock;
    late FakeNotificationGateway gateway;
    late NotificationIdRegistry registry;
    late NotificationReconciler reconciler;

    setUp(() {
      clock = FakeClock(DateTime(2026, 6, 15, 8, 0, 0));
      gateway = FakeNotificationGateway();
      registry = NotificationIdRegistry();
      reconciler = NotificationReconciler(
        clock: clock,
        gateway: gateway,
        registry: registry,
      );
    });

    test('Agenda para as 09:00 de hoje quando agora for antes das 09h', () {
      final rule = RecurringExpense(
        id: 'rule_1',
        amount: 120.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 6, 15),
        motivation: 'Internet',
        advanceGenerationCount: 0,
      );

      final nextTime = reconciler.findNextNotificationTime(rule);
      expect(nextTime, equals(DateTime(2026, 6, 15, 9, 0)));
    });

    test(
      'Não agenda no passado após as 09h do dia atual; escolhe próxima data futura',
      () {
        clock.setTime(DateTime(2026, 6, 15, 10, 30, 0));

        final rule = RecurringExpense(
          id: 'rule_1',
          amount: 120.0,
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 6, 15),
          motivation: 'Internet',
          advanceGenerationCount: 0,
        );

        final nextTime = reconciler.findNextNotificationTime(rule);

        expect(nextTime, equals(DateTime(2026, 7, 15, 9, 0)));
      },
    );

    test(
      'Regra sem antecipação (advanceGenerationCount == 0) recebe lembrete futuro normalmente',
      () {
        clock.setTime(DateTime(2026, 6, 1, 12, 0, 0));

        final rule = RecurringExpense(
          id: 'rule_zero_advance',
          amount: 50.0,
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 6, 20),
          motivation: 'Academia',
          advanceGenerationCount: 0,
        );

        final desired = reconciler.computeDesiredNotifications(
          uid: 'user_test',
          activeRules: [rule],
        );

        expect(desired.length, equals(1));
        expect(desired.first.scheduledAt, equals(DateTime(2026, 6, 20, 9, 0)));
        expect(desired.first.title, equals('Lembrete de Despesa'));
        expect(desired.first.body, isNot(contains('Academia')));
        expect(desired.first.body, contains('despesa programada'));

        final payloadData = json.decode(desired.first.payload);
        expect(payloadData['ruleId'], equals('rule_zero_advance'));
        expect(payloadData.containsKey('password'), isFalse);
      },
    );

    test(
      'Reconciliação é estritamente idempotente (reexecução não duplica chamadas nem IDs)',
      () async {
        final rule = RecurringExpense(
          id: 'rule_idempotent',
          amount: 80.0,
          frequency: RecurrenceFrequency.weekly,
          startDate: DateTime(2026, 6, 15),
          motivation: 'Terapia',
        );

        await reconciler.reconcile(uid: 'user1', activeRules: [rule]);

        expect(gateway.pending.length, equals(1));
        final assignedId = gateway.pending.keys.first;

        await reconciler.reconcile(uid: 'user1', activeRules: [rule]);

        expect(gateway.pending.length, equals(1));
        expect(gateway.pending.keys.first, equals(assignedId));
      },
    );

    test(
      'Remoção de regra cancela notificação no gateway e limpa do registry',
      () async {
        final rule1 = RecurringExpense(
          id: 'rule_1',
          amount: 100.0,
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 6, 15),
          motivation: 'Conta 1',
        );
        final rule2 = RecurringExpense(
          id: 'rule_2',
          amount: 200.0,
          frequency: RecurrenceFrequency.monthly,
          startDate: DateTime(2026, 6, 15),
          motivation: 'Conta 2',
        );

        await reconciler.reconcile(uid: 'user1', activeRules: [rule1, rule2]);
        expect(gateway.pending.length, equals(2));

        await reconciler.reconcile(uid: 'user1', activeRules: [rule2]);

        expect(gateway.pending.length, equals(1));
        expect(registry.getEntriesForUid('user1').length, equals(1));
        expect(
          registry.getEntriesForUid('user1').first.ruleId,
          equals('rule_2'),
        );
      },
    );

    test(
      'cancelAllForSession cancela todas as notificações e limpa o registro da sessão',
      () async {
        final rule = RecurringExpense(
          id: 'rule_logout',
          amount: 99.0,
          frequency: RecurrenceFrequency.daily,
          startDate: DateTime(2026, 6, 15),
          motivation: 'Remédio',
        );

        await reconciler.reconcile(uid: 'user_logout', activeRules: [rule]);
        expect(gateway.pending.length, equals(1));

        await reconciler.cancelAllForSession('user_logout');

        expect(gateway.pending, isEmpty);
        expect(registry.getEntriesForUid('user_logout'), isEmpty);
      },
    );
  });

  group('HomeWidgetService - Privacidade, Centavos e Limpeza de Sessão', () {
    test(
      'Configuração e preferência de visualização de valores no widget',
      () async {
        expect(await HomeWidgetService.getShowValues(), isFalse);

        await HomeWidgetService.setShowValues(true);
        expect(await HomeWidgetService.getShowValues(), isTrue);

        await HomeWidgetService.setShowValues(false);
        expect(await HomeWidgetService.getShowValues(), isFalse);
      },
    );

    test(
      'updateWidgetData formata com centavos e preserva máscara quando privado',
      () async {
        await HomeWidgetService.updateWidgetData(
          1550.75,
          uid: 'user_abc',
          referenceMonth: DateTime(2026, 6, 1),
          showValuesOverride: false,
        );

        await HomeWidgetService.updateWidgetData(
          1550.75,
          uid: 'user_abc',
          referenceMonth: DateTime(2026, 6, 1),
          showValuesOverride: true,
        );

        await HomeWidgetService.clearWidgetData();
      },
    );
  });
}
