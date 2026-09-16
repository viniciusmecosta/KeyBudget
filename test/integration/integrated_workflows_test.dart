import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:key_budget/core/import_export/backup_service.dart';
import 'package:key_budget/core/import_export/csv_import_parser.dart';
import 'package:key_budget/core/import_export/import_service.dart';
import 'package:key_budget/core/import_export/raw_storage.dart';
import 'package:key_budget/core/import_export/restore_service.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/notifications/notification_gateway.dart';
import 'package:key_budget/core/notifications/notification_id_registry.dart';
import 'package:key_budget/core/notifications/notification_reconciler.dart';
import 'package:key_budget/core/operations/session_context.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/core/services/home_widget_service.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:key_budget/features/analysis/domain/analysis_calculator.dart';
import 'package:key_budget/features/analysis/domain/analysis_query.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/expenses/application/recurrence_deletion_service.dart';
import 'package:key_budget/features/expenses/application/recurrence_reconciliation_service.dart';
import 'package:key_budget/features/expenses/application/recurrence_service.dart';
import 'package:key_budget/features/expenses/domain/recurrence_occurrence.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/repository/recurrence_occurrence_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> store = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      store[key] = value;
    } else {
      store.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    store.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      Map.from(store);
}

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

class FakeRecurringExpenseRepository implements RecurringExpenseRepository {
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

class FakeRecurrenceOccurrenceRepository implements RecurrenceOccurrenceRepository {
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

class FakeCredentialRepository implements CredentialRepository {
  final Map<String, Credential> storage = {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> addCredential(String userId, Credential cred) async {
    final id = cred.id ?? 'cred_${storage.length + 1}';
    storage[id] = cred.copyWith(id: id);
  }

  @override
  Future<void> deleteCredential(String userId, String credentialId) async {
    storage.remove(credentialId);
  }

  @override
  Future<List<Credential>> getCredentialsForUser(String userId) async {
    return storage.values.toList();
  }
}

class FakeEncryptionService extends Fake implements EncryptionService {
  @override
  String encryptData(String plainText) => base64Encode(utf8.encode('cipher_$plainText'));

  @override
  String decryptData(String encryptedText) =>
      utf8.decode(base64Decode(encryptedText)).replaceFirst('cipher_', '');
}

class FakeUserCredential extends Fake implements firebase.UserCredential {}

class FakeAuthRepository extends Fake implements AuthRepository {
  String? lastLoginEmail;
  String? lastLoginPassword;

  @override
  Stream<firebase.User?> get firebaseAuthStateChanges => const Stream.empty();

  @override
  Stream<User?> getUserProfileStream(String uid) => Stream.value(
        User(id: uid, name: 'Tester', email: 'tester@test.com', appLocked: true),
      );

  @override
  Future<firebase.UserCredential> signInWithEmail(String email, String password) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    return FakeUserCredential();
  }

  @override
  Future<void> ensureCategoriesExist(String userId) async {}
}

class FakeLocalAuthentication extends Fake implements LocalAuthentication {
  bool isDeviceSupportedValue = true;
  bool canCheckBiometricsValue = true;
  List<BiometricType> biometrics = [BiometricType.fingerprint];
  bool authenticateResult = true;
  PlatformException? throwOnAuth;

  @override
  Future<bool> isDeviceSupported() async => isDeviceSupportedValue;

  @override
  Future<bool> get canCheckBiometrics async => canCheckBiometricsValue;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => biometrics;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    if (throwOnAuth != null) throw throwOnAuth!;
    return authenticateResult;
  }

  @override
  Future<bool> stopAuthentication() async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testClock = TestAppClock(DateTime.utc(2026, 6, 15, 12, 0, 0));
  const testSession = SessionContext(
    userId: 'user_integrated_123',
    sessionGeneration: 1,
  );

  group('Matriz Integrada — Validação dos 5 Fluxos Canônicos', () {
    test('Fluxo 1 — Atualizar uma conta antiga: preservação de vínculos, mapas e sem backfill cego', () {
      final legacyRawMap = {
        'amount': 150.55,
        'date': {'_seconds': 1718452800, '_nanoseconds': 0},
        'motivation': 'Aluguel Antigo',
        'custom_tag_x': 'valor_legado_intacto',
        'unsupported_feature_flag': true,
      };

      final expense = Expense.fromMap(legacyRawMap, 'exp_legada_01');
      expect(expense.id, equals('exp_legada_01'));
      expect(expense.money.amountMinor, equals(15055));
      expect(expense.unmappedData['custom_tag_x'], equals('valor_legado_intacto'));
      expect(expense.unmappedData['unsupported_feature_flag'], isTrue);

      final edited = expense.copyWith(motivation: 'Aluguel Atualizado');
      final serialized = edited.toMap();
      expect(serialized['motivation'], equals('Aluguel Atualizado'));
      expect(serialized['custom_tag_x'], equals('valor_legado_intacto'));
      expect(serialized['unsupported_feature_flag'], isTrue);

      final fakeRecRepo = FakeRecurringExpenseRepository();
      final fakeOccRepo = FakeRecurrenceOccurrenceRepository();
      final reconciliationService = RecurrenceReconciliationService(
        recurringRepository: fakeRecRepo,
        occurrenceRepository: fakeOccRepo,
      );

      final rule = RecurringExpense(
        id: 'rec_l01',
        amount: 150.0,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2024, 1, 31),
        dayOfMonth: 31,
      );

      final report = reconciliationService.simulateRule(
        rule: rule,
        linkedExpenses: [
          expense.copyWith(id: 'e1', date: DateTime(2024, 1, 31)),
          expense.copyWith(id: 'e2', date: DateTime(2024, 1, 31)),
        ],
      );

      expect(report.hasDuplicates, isTrue);
      expect(report.suggestedState, equals('paused'));

      expect(fakeRecRepo.storage.isEmpty, isTrue);
      expect(fakeOccRepo.storage.isEmpty, isTrue);
    });

    test('Fluxo 2 — Backup e recuperação real: verificação de integridade e idempotência de restauração', () async {
      final sourceStorage = MemoryRawStorage();
      final targetStorage = MemoryRawStorage();
      final fakeSecureStorage = FakeSecureStorage();

      sourceStorage.documents['users/${testSession.userId}/categories/cat_home'] = {
        'id': 'cat_home',
        'name': 'Moradia',
        'color': 4283215696,
        'icon': 'home',
      };
      sourceStorage.documents['users/${testSession.userId}/expenses/exp_backup_1'] = {
        'id': 'exp_backup_1',
        'amount': 250.0,
        'date': '2026-06-01T12:00:00.000',
        'motivation': 'Monitor',
        'custom_prop': 42,
      };

      final backupService = BackupService(
        rawReader: sourceStorage,
        sessionContext: testSession,
        clock: testClock,
      );

      final backupResult = await backupService.createBackup(
        password: 'SenhaForte123!#',
      );
      expect(backupResult.isSuccess, isTrue);
      expect(backupResult.data, isNotNull);

      final envelopeBytes = backupResult.data!.envelopeBytes;

      final restoreService = RestoreService(
        rawReader: targetStorage,
        rawWriter: targetStorage,
        sessionContext: testSession,
        clock: testClock,
        secureStorage: fakeSecureStorage,
      );

      final previewResult = await restoreService.previewRestore(
        backupBytes: envelopeBytes,
        password: 'SenhaForte123!#',
      );
      expect(previewResult.isSuccess, isTrue);
      expect(targetStorage.documents.isEmpty, isTrue);

      final plan = previewResult.data!;
      expect(plan.createCount, equals(2));

      final restoreResult1 = await restoreService.executeRestore(
        plan: plan,
        backupBytes: envelopeBytes,
        password: 'SenhaForte123!#',
      );
      expect(restoreResult1.isSuccess, isTrue);
      expect(targetStorage.documents.length, equals(2));

      final previewResult2 = await restoreService.previewRestore(
        backupBytes: envelopeBytes,
        password: 'SenhaForte123!#',
      );
      expect(previewResult2.isSuccess, isTrue);
      final plan2 = previewResult2.data!;

      expect(plan2.skipCount, equals(2));
      expect(plan2.createCount, equals(0));

      final restoreResult2 = await restoreService.executeRestore(
        plan: plan2,
        backupBytes: envelopeBytes,
        password: 'SenhaForte123!#',
      );
      expect(restoreResult2.isSuccess, isTrue);

      expect(targetStorage.documents.length, equals(2));
    });

    test('Fluxo 3 — Concorrência recorrente: idempotência, atomicidade e tombstones', () async {
      final fakeExpenseRepo = FakeExpenseRepository();
      final fakeRecurringRepo = FakeRecurringExpenseRepository();
      final fakeOccurrenceRepo = FakeRecurrenceOccurrenceRepository();

      final recurrenceService = RecurrenceService(
        expenseRepository: fakeExpenseRepo,
        recurringRepository: fakeRecurringRepo,
        occurrenceRepository: fakeOccurrenceRepo,
        clock: testClock,
      );

      final rule = RecurringExpense(
        id: 'rule_concurrent',
        amount: 89.90,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 6, 1),
        motivation: 'Streaming',
        advanceGenerationCount: 0,
      );
      await fakeRecurringRepo.addRecurringExpense(testSession.userId, rule);

      final gen1 = await recurrenceService.generatePendingOccurrences(
        testSession.userId,
        rulesToProcess: [rule],
      );
      final gen2 = await recurrenceService.generatePendingOccurrences(
        testSession.userId,
        rulesToProcess: [rule],
      );

      expect(gen1.isSuccess, isTrue);
      expect(gen2.isSuccess, isTrue);

      expect(fakeExpenseRepo.storage.length, equals(1));
      expect(fakeOccurrenceRepo.storage.length, equals(1));

      final deletionService = RecurrenceDeletionService(
        recurringRepository: fakeRecurringRepo,
        expenseRepository: fakeExpenseRepo,
        occurrenceRepository: fakeOccurrenceRepo,
        clock: testClock,
      );

      final createdExpense = fakeExpenseRepo.storage.values.first;
      final delResult = await deletionService.deleteIndividualOccurrence(
        userId: testSession.userId,
        expense: createdExpense,
      );
      expect(delResult.isSuccess, isTrue);
      expect(fakeExpenseRepo.storage.isEmpty, isTrue);

      final gen3 = await recurrenceService.generatePendingOccurrences(
        testSession.userId,
        rulesToProcess: [rule],
      );
      expect(gen3.isSuccess, isTrue);
      expect(gen3.data, isEmpty);
      expect(fakeExpenseRepo.storage.isEmpty, isTrue);
    });

    test('Fluxo 4 — Importar, analisar e exportar: integridade contábil e congelamento de snapshot', () async {
      final csvService = CsvService();
      final expenseRepo = FakeExpenseRepository();
      final credRepo = FakeCredentialRepository();
      final recRepo = FakeRecurringExpenseRepository();
      final encService = FakeEncryptionService();

      final importService = ImportService(
        expenseRepository: expenseRepo,
        credentialRepository: credRepo,
        recurringRepository: recRepo,
        encryptionService: encService,
      );

      const csvContent = '''Data,Descricao,Valor,Tipo
10/06/2026,Cafezinho,5.00,Despesa
10/06/2026,Cafezinho,5.00,Despesa
12/06/2026,Salario,1500.00,Receita''';

      final parserResult = const CsvImportParser().parseString(csvContent);
      expect(parserResult.isValid, isTrue);
      expect(parserResult.rows.length, equals(3));

      final plan = await importService.preparePlan(
        userId: testSession.userId,
        fileContent: csvContent,
        fileName: 'extrato.csv',
      );

      expect(plan.validCount, equals(3));

      expect(
        plan.lineResults[0].deduplicationFingerprint,
        isNot(equals(plan.lineResults[1].deduplicationFingerprint)),
      );

      final applyResult = await importService.applyPlan(
        userId: testSession.userId,
        plan: plan,
      );
      expect(applyResult.isSuccess, isTrue);
      expect(expenseRepo.storage.length, equals(3));

      final importedExpenses = expenseRepo.storage.values.toList();
      final query = AnalysisQuery.forMonth(DateTime(2026, 6, 1));
      final snapshot = AnalysisCalculator.calculate(
        query: query,
        expenses: importedExpenses,
        categories: [],
        capturedAt: testClock.now(),
      );

      expect(snapshot.totalExpenses, equals(Money.fromCents(1000)));
      expect(snapshot.totalIncomes, equals(Money.fromCents(150000)));
      expect(snapshot.balance, equals(Money.fromCents(149000)));
      expect(snapshot.isInvariantsValid, isTrue);

      final exportedCsv = csvService.generateAnalysisCsvContent(snapshot);
      expect(exportedCsv.contains('Total de Despesas'), isTrue);
      expect(exportedCsv.contains('10,00'), isTrue);
      expect(exportedCsv.contains('1.500,00'), isTrue);
    });

    test('Fluxo 5 — Acesso e superfícies externas: compatibilidade de senhas, widget e reconciliação', () async {

      final fakeAuthRepo = FakeAuthRepository();
      final fakeLocalAuth = FakeLocalAuthentication();
      final fakeSecureStorage = FakeSecureStorage();
      final localAuthService = LocalAuthService(
        auth: fakeLocalAuth,
        storage: fakeSecureStorage,
      );
      final authViewModel = AuthViewModel(
        authRepository: fakeAuthRepo,
        localAuthService: localAuthService,
        listenToAuthChanges: false,
      );

      const rawPasswordWithSpaces = '  senha_secreta_com_espacos  ';
      await authViewModel.loginUser(
        email: '  test@keybudget.com  ',
        password: rawPasswordWithSpaces,
      );

      expect(fakeAuthRepo.lastLoginEmail, equals('test@keybudget.com'));
      expect(fakeAuthRepo.lastLoginPassword, equals(rawPasswordWithSpaces));

      final unlockRes = await authViewModel.authenticateWithBiometrics();
      expect(unlockRes, isFalse);

      fakeLocalAuth.throwOnAuth = PlatformException(code: 'LockedOut');
      final authLockout = await localAuthService.authenticateLocal();
      expect(authLockout, equals(LocalAuthResult.temporarilyLockedOut));

      final gateway = FakeNotificationGateway();
      final registry = NotificationIdRegistry();
      final reconciler = NotificationReconciler(
        clock: testClock,
        gateway: gateway,
        registry: registry,
      );

      final rule = RecurringExpense(
        id: 'rule_reminder',
        amount: 199.90,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 6, 20),
        motivation: 'Seguro',
      );

      await reconciler.reconcile(
        uid: testSession.userId,
        activeRules: [rule],
      );
      expect(gateway.pending.length, equals(1));

      await HomeWidgetService.updateWidgetData(
        100.0,
        uid: testSession.userId,
        referenceMonth: DateTime(2026, 6, 1),
        showValuesOverride: false,
      );

      await reconciler.cancelAllForSession(testSession.userId);
      await HomeWidgetService.clearWidgetData();

      expect(gateway.pending, isEmpty);
      expect(registry.getEntriesForUid(testSession.userId), isEmpty);
    });
  });
}
