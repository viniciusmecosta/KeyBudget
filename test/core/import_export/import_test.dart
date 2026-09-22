import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/import_export/csv_import_parser.dart';
import 'package:key_budget/core/import_export/import_service.dart';
import 'package:key_budget/core/import_export/import_validation.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/money/money_parser.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
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
  Future<List<Expense>> getExpensesForUser(String userId) async {
    return storage.values.toList();
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
  Future<void> deleteRecurringExpense(String userId, String expenseId) async {
    storage.remove(expenseId);
  }

  Future<List<RecurringExpense>> getRecurringExpensesForUser(String userId) async {
    return storage.values.toList();
  }
}

class FakeEncryptionService extends Fake implements EncryptionService {
  @override
  String encryptData(String plainText) => base64Encode(utf8.encode('ciphertext_$plainText'));

  @override
  String decryptData(String encryptedText) =>
      utf8.decode(base64Decode(encryptedText)).replaceFirst('ciphertext_', '');
}

void main() {
  group('CsvImportParser Robustness', () {
    const parser = CsvImportParser();

    test('Strips UTF-8 BOM and sniffs comma delimiter correctly', () {
      const csvWithBom = '\uFEFFData,Descricao,Valor\n15/05/2024,Supermercado,"50,25"';
      final result = parser.parseString(csvWithBom);

      expect(result.isValid, isTrue);
      expect(result.hadBom, isTrue);
      expect(result.detectedDelimiter, equals(','));
      expect(result.headers, equals(['Data', 'Descricao', 'Valor']));
      expect(result.detectedType, equals(CsvImportType.expenses));
      expect(result.rows.length, equals(1));
      expect(result.rows.first.values['motivation'], equals('Supermercado'));
      expect(result.rows.first.values['amount'], equals('50,25'));
    });

    test('Sniffs semicolon delimiter and trims whitespace', () {
      const csvSemicolon = 'Data ; Titulo ; Valor ; Tipo\n2024-06-01 ; Salario ; 3500.00 ; Receita';
      final result = parser.parseString(csvSemicolon);

      expect(result.isValid, isTrue);
      expect(result.detectedDelimiter, equals(';'));
      expect(result.headers, contains('Titulo'));
      expect(result.rows.first.values['location'], equals('Salario'));
      expect(result.rows.first.values['amount'], equals('3500.00'));
      expect(result.rows.first.values['isincome'], equals('Receita'));
    });

    test('Parses multiline quoted values and escaped quotes', () {
      const complexCsv = 'id,notes,amount\n1,"Linha 1\nLinha 2 com ""aspas""",100.00';
      final result = parser.parseString(complexCsv);

      expect(result.isValid, isTrue);
      final row = result.rows.first;
      expect(row.values['notes'], equals('Linha 1\nLinha 2 com "aspas"'));
      expect(row.values['amount'], equals('100.00'));
    });

    test('Fails gracefully when row has column mismatch', () {

      const brokenCsv = 'Data,Descricao,Valor\n15/05/2024,Mercado,50.00\n16/05/2024,Padaria,10.00,ExtraCol';
      final result = parser.parseString(brokenCsv);

      expect(result.rows.any((r) => r.hasError), isTrue);
    });

    test('Fails when empty or only whitespace', () {
      final result = parser.parseString('   \n  \n');
      expect(result.isValid, isFalse);
      expect(result.structuralErrors.first, contains('vazio'));
    });
  });

  group('Strict Validations (Date, Money, Categories, Credentials)', () {
    test('DateParser strictly rejects impossible calendar dates (31/02, 29/02 non-leap)', () {
      expect(ImportValidation.parseStrictDate('31/02/2024'), isNull);
      expect(ImportValidation.parseStrictDate('29/02/2023'), isNull);
      expect(ImportValidation.parseStrictDate('29/02/2024'), isNotNull);
      expect(ImportValidation.parseStrictDate('30/04/2024'), isNotNull);
      expect(ImportValidation.parseStrictDate('31/04/2024'), isNull);
      expect(ImportValidation.parseStrictDate('00/10/2024'), isNull);
      expect(ImportValidation.parseStrictDate('2024-02-29'), isNotNull);
      expect(ImportValidation.parseStrictDate('2023-02-29'), isNull);
    });

    test('MoneyParser strictly rejects invalid strings without defaulting to zero', () {
      expect(() => MoneyParser.parse('R\$ ABC'), throwsA(isA<FormatException>()));
      expect(() => MoneyParser.parse(''), throwsA(isA<FormatException>()));
      expect(() => MoneyParser.parse('12.3456'), throwsA(isA<ExtraDecimalsException>()));

      expect(MoneyParser.parse('R\$ 1.250,50').amountMinor, equals(125050));
      expect(MoneyParser.parse('1250.50').amountMinor, equals(125050));
      expect(MoneyParser.parse('-45,00').amountMinor, equals(-4500));
    });

    test('Credential validation rejects missing location, login, or password', () {
      const validRow = RawCsvRow(
        lineNumber: 2,
        values: {'location': 'Banco', 'login': 'user', 'password': 'password123'},
        rawTokens: ['Banco', 'user', 'password123'],
      );
      final validRes = ImportValidation.validateCredentialRow(rawRow: validRow, occurrenceIndex: 0);
      expect(validRes.isValid, isTrue);
      expect(validRes.parsedItem?.location, equals('Banco'));
      expect(validRes.parsedItem?.login, equals('user'));
      expect(validRes.parsedItem?.encryptedPassword, equals('password123'));

      const missingPassRow = RawCsvRow(
        lineNumber: 3,
        values: {'location': 'Banco', 'login': 'user', 'password': ''},
        rawTokens: ['Banco', 'user', ''],
      );
      final missingPassRes = ImportValidation.validateCredentialRow(rawRow: missingPassRow, occurrenceIndex: 0);
      expect(missingPassRes.isValid, isFalse);
      expect(missingPassRes.errors.any((e) => e.contains('Senha é obrigatória')), isTrue);

      const missingLocRow = RawCsvRow(
        lineNumber: 4,
        values: {'location': '', 'login': 'user', 'password': 'secret'},
        rawTokens: ['', 'user', 'secret'],
      );
      final missingLocRes = ImportValidation.validateCredentialRow(rawRow: missingLocRow, occurrenceIndex: 0);
      expect(missingLocRes.isValid, isFalse);
    });

    test('Recurring expenses are validated and imported as paused drafts', () {
      const recRow = RawCsvRow(
        lineNumber: 2,
        values: {
          'motivation': 'Aluguel',
          'amount': '1200,00',
          'frequency': 'mensal',
          'startdate': '10/01/2024',
        },
        rawTokens: ['Aluguel', '1200,00', 'mensal', '10/01/2024'],
      );

      final result = ImportValidation.validateRecurringRow(rawRow: recRow, occurrenceIndex: 0);
      expect(result.isValid, isTrue);
      expect(result.parsedItem?.generationState, equals('paused'));
      expect(result.parsedItem?.money, equals(Money.fromCents(120000)));
      expect(result.warnings.any((w) => w.contains('rascunho pausado')), isTrue);
    });
  });

  group('Import Execution Plan & Preview', () {
    late FakeExpenseRepository expenseRepo;
    late FakeCredentialRepository credRepo;
    late FakeRecurringRepository recurringRepo;
    late FakeEncryptionService encryptionService;
    late ImportService importService;

    setUp(() {
      expenseRepo = FakeExpenseRepository();
      credRepo = FakeCredentialRepository();
      recurringRepo = FakeRecurringRepository();
      encryptionService = FakeEncryptionService();
      importService = ImportService(
        expenseRepository: expenseRepo,
        credentialRepository: credRepo,
        recurringRepository: recurringRepo,
        encryptionService: encryptionService,
      );
    });

    test('preparePlan prepares cold preview without writing to database', () async {
      const csv = '''Data,Descricao,Valor,Tipo
15/05/2024,Supermercado,150.00,Despesa
16/05/2024,Salario,3000.00,Receita
31/02/2024,DataInvalida,50.00,Despesa
18/05/2024,Farmacia,INVALIDO,Despesa''';

      final plan = await importService.preparePlan(
        userId: 'user_test',
        fileContent: csv,
        fileName: 'extrato.csv',
      );

      expect(plan.detectedType, equals(CsvImportType.expenses));
      expect(plan.totalLines, equals(4));
      expect(plan.validCount, equals(2));
      expect(plan.invalidCount, equals(2));
      expect(plan.totalExpenseMinor, equals(15000));
      expect(plan.totalIncomeMinor, equals(300000));
      expect(plan.canProceed, isTrue);

      expect((await expenseRepo.getExpensesForUser('user_test')).isEmpty, isTrue);
    });

    test('Two legitimate identical lines in the same file get separate distinct keys', () async {

      const csv = '''Data,Descricao,Valor
10/05/2024,Cafezinho,5.00
10/05/2024,Cafezinho,5.00''';

      final plan = await importService.preparePlan(
        userId: 'user_test',
        fileContent: csv,
        fileName: 'gastos.csv',
      );

      expect(plan.validCount, equals(2));
      final line1 = plan.lineResults[0];
      final line2 = plan.lineResults[1];

      expect(line1.deduplicationFingerprint, isNot(equals(line2.deduplicationFingerprint)));

      final result = await importService.applyPlan(
        userId: 'user_test',
        plan: plan,
        importOnlyValid: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.createdCount, equals(2));

      final stored = await expenseRepo.getExpensesForUser('user_test');
      expect(stored.length, equals(2));
      expect(stored.every((e) => e.motivation == 'Cafezinho'), isTrue);
    });

    test('Re-importing the exact same file skips duplicates idempotently', () async {
      const csv = '''Data,Descricao,Valor
10/05/2024,Cafezinho,5.00''';

      final plan1 = await importService.preparePlan(
        userId: 'user_test',
        fileContent: csv,
        fileName: 'gastos.csv',
      );

      final apply1 = await importService.applyPlan(
        userId: 'user_test',
        plan: plan1,
        importOnlyValid: true,
      );
      expect(apply1.data?.createdCount, equals(1));

      final existing = await expenseRepo.getExpensesForUser('user_test');
      final plan2 = await importService.preparePlan(
        userId: 'user_test',
        fileContent: csv,
        fileName: 'gastos.csv',
        existingExpenses: existing,
      );

      expect(plan2.lineResults.first.status, equals(ImportRowStatus.skippedDuplicate));

      final apply2 = await importService.applyPlan(
        userId: 'user_test',
        plan: plan2,
        importOnlyValid: true,
      );
      expect(apply2.isSuccess, isFalse);

      final stored = await expenseRepo.getExpensesForUser('user_test');
      expect(stored.length, equals(1));
    });

    test('Credentials import encrypts passwords and rollback removes all created docs', () async {
      const csv = '''Local,Login,Senha
Banco Alfa,usuario1,segredo123
Serviço Beta,usuario2,segredo456''';

      final plan = await importService.preparePlan(
        userId: 'user_test',
        fileContent: csv,
        fileName: 'senhas.csv',
      );

      expect(plan.detectedType, equals(CsvImportType.credentials));
      expect(plan.validCount, equals(2));

      final applyResult = await importService.applyPlan(
        userId: 'user_test',
        plan: plan,
      );

      expect(applyResult.isSuccess, isTrue);
      final importReport = applyResult.data!;
      expect(importReport.createdCount, equals(2));

      final storedCreds = await credRepo.getCredentialsForUser('user_test');
      expect(storedCreds.length, equals(2));

      expect(storedCreds.first.encryptedPassword, isNot(contains('segredo123')));

      final rollbackRes = await importService.rollbackImport(
        userId: 'user_test',
        type: CsvImportType.credentials,
        report: importReport,
      );

      expect(rollbackRes.isSuccess, isTrue);
      final afterRollback = await credRepo.getCredentialsForUser('user_test');
      expect(afterRollback.isEmpty, isTrue);
    });
  });
}
