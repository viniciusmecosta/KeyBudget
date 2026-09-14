import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:key_budget/features/expenses/application/recurrence_deletion_service.dart';
import 'package:key_budget/features/expenses/application/recurrence_reconciliation_service.dart';
import 'package:key_budget/features/expenses/application/recurrence_service.dart';
import 'package:key_budget/features/expenses/domain/recurrence_occurrence.dart';
import 'package:key_budget/features/expenses/domain/recurrence_schedule.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/repository/recurrence_occurrence_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';

class FakeExpenseRepository implements ExpenseRepository {
  final Map<String, Expense> storage = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> addExpense(String userId, Expense expense) async {
    final id = expense.id ?? 'exp_${storage.length + 1}';
    storage[id] = expense.copyWith(id: id);
  }

  @override
  Future<void> addExpensesBatch(String userId, List<Expense> expenses) async {
    for (final exp in expenses) {
      await addExpense(userId, exp);
    }
  }

  @override
  Future<void> deleteExpense(String userId, String expenseId) async {
    storage.remove(expenseId);
  }

  @override
  Future<void> restoreExpense(String userId, Expense expense) async {
    if (expense.id != null) {
      storage[expense.id!] = expense;
    }
  }

  @override
  Future<List<Expense>> getExpensesForUser(String userId) async {
    return storage.values.toList();
  }
}

class FakeRecurringRepository implements RecurringExpenseRepository {
  final Map<String, RecurringExpense> storage = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> addRecurringExpense(String userId, RecurringExpense exp) async {
    final id = exp.id ?? 'rec_${storage.length + 1}';
    storage[id] = exp.copyWith(id: id);
  }

  @override
  Future<void> updateRecurringExpense(String userId, RecurringExpense exp) async {
    if (exp.id != null) {
      storage[exp.id!] = exp;
    }
  }

  @override
  Future<void> deleteRecurringExpense(String userId, String expenseId) async {
    storage.remove(expenseId);
  }

  @override
  Future<void> restoreRecurringExpense(String userId, RecurringExpense exp) async {
    if (exp.id != null) {
      storage[exp.id!] = exp;
    }
  }

  @override
  Stream<List<RecurringExpense>> getRecurringExpensesStream(String userId) {
    return Stream.value(storage.values.toList());
  }
}

class FakeOccurrenceRepository implements RecurrenceOccurrenceRepository {
  final Map<String, RecurrenceOccurrence> storage = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<RecurrenceOccurrence?> getOccurrence(String userId, String key) async {
    return storage[key];
  }

  @override
  Future<void> saveOccurrence(String userId, RecurrenceOccurrence occ) async {
    storage[occ.occurrenceKey] = occ;
  }

  @override
  Future<void> saveOccurrencesBatch(String userId, List<RecurrenceOccurrence> list) async {
    for (final o in list) {
      storage[o.occurrenceKey] = o;
    }
  }

  @override
  Future<List<RecurrenceOccurrence>> getAllOccurrences(String userId) async {
    return storage.values.toList();
  }

  @override
  Future<List<RecurrenceOccurrence>> getOccurrencesForRule(String userId, String ruleId) async {
    return storage.values.where((o) => o.recurringExpenseId == ruleId).toList();
  }

  @override
  Future<void> deleteOccurrence(String userId, String occurrenceKey) async {
    storage.remove(occurrenceKey);
  }
}

void main() {
  group('RecurrenceSchedule Pure Engine', () {
    test('Dia 31 em ano bissexto (2024) gera 29/02 e março volta ao dia 31', () {
      final rule = RecurringExpense(
        id: 'rule_leap',
        amount: 100.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 31),
        dayOfMonth: 31,
        scheduleVersion: 1,
      );

      final d1 = RecurrenceSchedule.getNextCandidateDate(rule: rule, cursor: null);
      expect(d1, DateTime(2024, 1, 31));

      final d2 = RecurrenceSchedule.getNextCandidateDate(rule: rule, cursor: d1);
      expect(d2, DateTime(2024, 2, 29));

      final d3 = RecurrenceSchedule.getNextCandidateDate(rule: rule, cursor: d2);
      expect(d3, DateTime(2024, 3, 31));
    });

    test('Dia 31 em ano não-bissexto (2023) gera 28/02 e março volta ao dia 31', () {
      final rule = RecurringExpense(
        id: 'rule_non_leap',
        amount: 100.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2023, 1, 31),
        dayOfMonth: 31,
        scheduleVersion: 1,
      );

      final d1 = RecurrenceSchedule.getNextCandidateDate(rule: rule, cursor: null);
      expect(d1, DateTime(2023, 1, 31));

      final d2 = RecurrenceSchedule.getNextCandidateDate(rule: rule, cursor: d1);
      expect(d2, DateTime(2023, 2, 28));

      final d3 = RecurrenceSchedule.getNextCandidateDate(rule: rule, cursor: d2);
      expect(d3, DateTime(2023, 3, 31));
    });

    test('Sem dayOfMonth na versão legada (scheduleVersion: 0): progressão sem âncora preservada', () {
      final legacyRule = RecurringExpense(
        id: 'rule_legacy',
        amount: 100.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2023, 1, 31),
        dayOfMonth: null,
        scheduleVersion: 0,
      );

      final d1 = RecurrenceSchedule.getNextCandidateDate(rule: legacyRule, cursor: null);
      expect(d1, DateTime(2023, 1, 31));

      final d2 = RecurrenceSchedule.getNextCandidateDate(rule: legacyRule, cursor: d1);
      expect(d2, DateTime(2023, 2, 28));

      final d3 = RecurrenceSchedule.getNextCandidateDate(rule: legacyRule, cursor: d2);
      expect(d3, DateTime(2023, 3, 28));
    });

    test('isPastEndDate é inclusivo até 23:59:59.999 do dia civil', () {
      final endDate = DateTime(2024, 5, 10, 0, 0, 0);

      expect(
        RecurrenceSchedule.isPastEndDate(
          DateTime(2024, 5, 10, 14, 0, 0),
          endDate,
          scheduleVersion: 1,
        ),
        isFalse,
      );

      expect(
        RecurrenceSchedule.isPastEndDate(
          DateTime(2024, 5, 11, 0, 0, 0),
          endDate,
          scheduleVersion: 1,
        ),
        isTrue,
      );
    });

    test('getTargetHorizonDate calcula limite mensal correto sem estourar fevereiro', () {
      final febNow = DateTime(2024, 2, 15);
      final monthlyRule = RecurringExpense(
        amount: 50.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 1),
        advanceGenerationCount: 1,
      );

      final horizon = RecurrenceSchedule.getTargetHorizonDate(febNow, monthlyRule);
      expect(horizon.year, 2024);
      expect(horizon.month, 3);
      expect(horizon.day, 31);
    });
  });

  group('RecurrenceService & Idempotency', () {
    late FakeExpenseRepository expRepo;
    late FakeRecurringRepository recRepo;
    late FakeOccurrenceRepository occRepo;

    setUp(() {
      expRepo = FakeExpenseRepository();
      recRepo = FakeRecurringRepository();
      occRepo = FakeOccurrenceRepository();
    });

    test('Geração idempotente: dois aparelhos gerando a mesma regra não criam despesas duplicadas', () async {
      final testClock = TestAppClock(DateTime(2024, 4, 15));
      final service1 = RecurrenceService(
        expenseRepository: expRepo,
        recurringRepository: recRepo,
        occurrenceRepository: occRepo,
        clock: testClock,
      );
      final service2 = RecurrenceService(
        expenseRepository: expRepo,
        recurringRepository: recRepo,
        occurrenceRepository: occRepo,
        clock: testClock,
      );

      final rule = RecurringExpense.withMoney(
        id: 'rec_salary',
        money: Money.fromNumWithHalfAwayFromZero(3000.0),
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 5),
        dayOfMonth: 5,
        engineVersion: 1,
        scheduleVersion: 1,
      );
      await recRepo.addRecurringExpense('user_1', rule);

      final res1 = await service1.generatePendingOccurrences('user_1');
      expect(res1.isSuccess, isTrue);
      expect(res1.totalCount, 4);
      expect(expRepo.storage.length, 4);
      expect(occRepo.storage.length, 4);

      final res2 = await service2.generatePendingOccurrences('user_1');
      expect(res2.isSuccess, isTrue);
      expect(res2.totalCount, 0);
      expect(expRepo.storage.length, 4);
    });

    test('Tombstone suppression: despesa intencionalmente excluída não é recriada em nova geração', () async {
      final testClock = TestAppClock(DateTime(2024, 3, 10));
      final service = RecurrenceService(
        expenseRepository: expRepo,
        recurringRepository: recRepo,
        occurrenceRepository: occRepo,
        clock: testClock,
      );
      final delService = RecurrenceDeletionService(
        recurringRepository: recRepo,
        expenseRepository: expRepo,
        occurrenceRepository: occRepo,
        clock: testClock,
      );

      final rule = RecurringExpense.withMoney(
        id: 'rec_gym',
        money: Money.fromNumWithHalfAwayFromZero(120.0),
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 10),
        dayOfMonth: 10,
      );
      await recRepo.addRecurringExpense('user_1', rule);

      await service.generatePendingOccurrences('user_1');
      expect(expRepo.storage.length, 3);

      final febExpense = expRepo.storage.values.firstWhere((e) => e.date.month == 2);
      final delResult = await delService.deleteIndividualOccurrence(
        userId: 'user_1',
        expense: febExpense,
      );
      expect(delResult.isSuccess, isTrue);
      expect(expRepo.storage.length, 2);

      final febKey = RecurrenceOccurrence.generateKey(
        uid: 'user_1',
        recurringExpenseId: 'rec_gym',
        scheduledDateKey: '2024-02-10',
      );
      final tombstone = await occRepo.getOccurrence('user_1', febKey);
      expect(tombstone, isNotNull);
      expect(tombstone!.state, OccurrenceState.suppressed);

      final rewindedRule = recRepo.storage['rec_gym']!.copyWith(
        lastInstanceDate: DateTime(2024, 1, 10),
      );
      await recRepo.updateRecurringExpense('user_1', rewindedRule);

      final rerunResult = await service.generatePendingOccurrences('user_1');
      expect(rerunResult.isSuccess, isTrue);

      expect(expRepo.storage.values.any((e) => e.date.month == 2), isFalse);
      expect(expRepo.storage.length, 2);
    });

    test('Cursor adiantado e horizonte menor: não remove nem recria despesas futuras', () async {
      final testClock = TestAppClock(DateTime(2024, 2, 1));
      final service = RecurrenceService(
        expenseRepository: expRepo,
        recurringRepository: recRepo,
        occurrenceRepository: occRepo,
        clock: testClock,
      );

      final rule = RecurringExpense(
        id: 'rec_ahead',
        amount: 50.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 1),
        lastInstanceDate: DateTime(2024, 6, 1),
        advanceGenerationCount: 0,
      );
      await recRepo.addRecurringExpense('user_1', rule);

      final res = await service.generatePendingOccurrences('user_1');
      expect(res.isSuccess, isTrue);
      expect(res.totalCount, 0);
      expect(recRepo.storage['rec_ahead']!.lastInstanceDate, DateTime(2024, 6, 1));
    });
  });

  group('RecurrenceDeletionService & Full Undo', () {
    late FakeExpenseRepository expRepo;
    late FakeRecurringRepository recRepo;
    late FakeOccurrenceRepository occRepo;
    late RecurrenceDeletionService delService;

    setUp(() {
      expRepo = FakeExpenseRepository();
      recRepo = FakeRecurringRepository();
      occRepo = FakeOccurrenceRepository();
      delService = RecurrenceDeletionService(
        recurringRepository: recRepo,
        expenseRepository: expRepo,
        occurrenceRepository: occRepo,
        clock: TestAppClock(DateTime(2024, 4, 15, 12, 0, 0)),
      );
    });

    test('Modo onlyRule: exclui somente a regra, mantendo todas as despesas', () async {
      final rule = RecurringExpense(
        id: 'rec_rule_1',
        amount: 100.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 1),
      );
      await recRepo.addRecurringExpense('u1', rule);

      final exp1 = Expense(id: 'e1', amount: 100.0, date: DateTime(2024, 3, 1), recurringExpenseId: 'rec_rule_1');
      final exp2 = Expense(id: 'e2', amount: 100.0, date: DateTime(2024, 5, 1), recurringExpenseId: 'rec_rule_1');
      await expRepo.addExpensesBatch('u1', [exp1, exp2]);

      final res = await delService.deleteRule(
        userId: 'u1',
        rule: rule,
        mode: RecurrenceDeleteMode.onlyRule,
        allExpenses: [exp1, exp2],
      );

      expect(res.isSuccess, isTrue);
      expect(recRepo.storage.containsKey('rec_rule_1'), isFalse);
      expect(expRepo.storage.containsKey('e1'), isTrue);
      expect(expRepo.storage.containsKey('e2'), isTrue);
    });

    test('Modo futureOnly: exclui regra e despesas com data civil > hoje, preservando passadas e hoje', () async {
      final rule = RecurringExpense(
        id: 'rec_rule_1',
        amount: 100.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 1),
      );
      await recRepo.addRecurringExpense('u1', rule);

      final expPast = Expense(id: 'e_past', amount: 100.0, date: DateTime(2024, 3, 1), recurringExpenseId: 'rec_rule_1');
      final expToday = Expense(id: 'e_today', amount: 100.0, date: DateTime(2024, 4, 15, 10, 0, 0), recurringExpenseId: 'rec_rule_1');
      final expFuture = Expense(id: 'e_future', amount: 100.0, date: DateTime(2024, 5, 1), recurringExpenseId: 'rec_rule_1');
      await expRepo.addExpensesBatch('u1', [expPast, expToday, expFuture]);

      final res = await delService.deleteRule(
        userId: 'u1',
        rule: rule,
        mode: RecurrenceDeleteMode.futureOnly,
        allExpenses: [expPast, expToday, expFuture],
      );

      expect(res.isSuccess, isTrue);
      expect(recRepo.storage.containsKey('rec_rule_1'), isFalse);
      expect(expRepo.storage.containsKey('e_past'), isTrue);
      expect(expRepo.storage.containsKey('e_today'), isTrue);
      expect(expRepo.storage.containsKey('e_future'), isFalse);

      final snapshot = res.data!;
      final undoRes = await delService.undoDelete(userId: 'u1', snapshot: snapshot);
      expect(undoRes.isSuccess, isTrue);
      expect(recRepo.storage.containsKey('rec_rule_1'), isTrue);
      expect(expRepo.storage.containsKey('e_future'), isTrue);
    });

    test('Modo all e undoDelete: restaura regra e todas as despesas idênticas com IDs intactos', () async {
      final rule = RecurringExpense.withMoney(
        id: 'rec_rent',
        money: Money.fromCents(250000),
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 1),
      );
      await recRepo.addRecurringExpense('u1', rule);

      final exp1 = Expense(id: 'rent_jan', amount: 2500.0, date: DateTime(2024, 1, 1), recurringExpenseId: 'rec_rent');
      final exp2 = Expense(id: 'rent_feb', amount: 2500.0, date: DateTime(2024, 2, 1), recurringExpenseId: 'rec_rent');
      await expRepo.addExpensesBatch('u1', [exp1, exp2]);

      final delRes = await delService.deleteRule(
        userId: 'u1',
        rule: rule,
        mode: RecurrenceDeleteMode.all,
        allExpenses: [exp1, exp2],
      );

      expect(delRes.isSuccess, isTrue);
      expect(recRepo.storage.isEmpty, isTrue);
      expect(expRepo.storage.isEmpty, isTrue);

      final undoRes = await delService.undoDelete(userId: 'u1', snapshot: delRes.data!);
      expect(undoRes.isSuccess, isTrue);
      expect(recRepo.storage.containsKey('rec_rent'), isTrue);
      expect(recRepo.storage['rec_rent']!.money.amountMinor, 250000);
      expect(expRepo.storage.containsKey('rent_jan'), isTrue);
      expect(expRepo.storage.containsKey('rent_feb'), isTrue);
    });
  });

  group('RecurrenceReconciliationService', () {
    test('Simulação e reconciliação retrospectiva sem duplicar despesas existentes', () async {
      final expRepo = FakeExpenseRepository();
      final recRepo = FakeRecurringRepository();
      final occRepo = FakeOccurrenceRepository();

      final reconciler = RecurrenceReconciliationService(
        recurringRepository: recRepo,
        occurrenceRepository: occRepo,
      );

      final rule = RecurringExpense(
        id: 'rule_legacy_sync',
        amount: 200.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 1),
      );
      await recRepo.addRecurringExpense('u1', rule);

      final oldExp1 = Expense(id: 'old_1', amount: 200.0, date: DateTime(2024, 1, 1), recurringExpenseId: 'rule_legacy_sync');
      final oldExp2 = Expense(id: 'old_2', amount: 200.0, date: DateTime(2024, 2, 1), recurringExpenseId: 'rule_legacy_sync');
      await expRepo.addExpensesBatch('u1', [oldExp1, oldExp2]);

      final simReport = reconciler.simulateRule(
        rule: rule,
        linkedExpenses: [oldExp1, oldExp2],
      );
      expect(simReport.hasDuplicates, isFalse);
      expect(simReport.isSafeToGenerate, isTrue);

      final recResult = await reconciler.reconcileRule(
        userId: 'u1',
        rule: rule,
        linkedExpenses: [oldExp1, oldExp2],
      );
      expect(recResult.isSuccess, isTrue);

      final ledgerEntries = await occRepo.getOccurrencesForRule('u1', 'rule_legacy_sync');
      expect(ledgerEntries.length, 2);
      expect(ledgerEntries.first.expenseIds, contains('old_1'));
      expect(ledgerEntries.last.expenseIds, contains('old_2'));
      expect(expRepo.storage.length, 2);
    });

    test('Diagnóstico de duplicatas antigas: detecta conflito sem apagar e pausa regra com segurança', () {
      final reconciler = RecurrenceReconciliationService(
        recurringRepository: FakeRecurringRepository(),
        occurrenceRepository: FakeOccurrenceRepository(),
      );

      final rule = RecurringExpense(
        id: 'rule_dups',
        amount: 50.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 1),
      );

      final dup1 = Expense(id: 'dup_a', amount: 50.0, date: DateTime(2024, 1, 1), recurringExpenseId: 'rule_dups');
      final dup2 = Expense(id: 'dup_b', amount: 50.0, date: DateTime(2024, 1, 1), recurringExpenseId: 'rule_dups');

      final report = reconciler.simulateRule(rule: rule, linkedExpenses: [dup1, dup2]);
      expect(report.hasDuplicates, isTrue);
      expect(report.isSafeToGenerate, isFalse);
      expect(report.suggestedState, 'paused');
    });
  });
}
