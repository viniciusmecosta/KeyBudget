import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/import_export/backup_codec.dart';
import 'package:key_budget/core/import_export/backup_crypto.dart';
import 'package:key_budget/core/import_export/backup_service.dart';
import 'package:key_budget/core/import_export/import_plan.dart';
import 'package:key_budget/core/import_export/operation_journal.dart';
import 'package:key_budget/core/import_export/raw_storage.dart';
import 'package:key_budget/core/import_export/restore_service.dart';
import 'package:key_budget/core/operations/session_context.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/core/time/app_clock.dart';

import '../../fixtures/legacy/legacy_fixtures.dart';

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

class _CredentialCipher extends Fake implements EncryptionService {
  final String prefix;

  _CredentialCipher(this.prefix);

  @override
  String decryptData(String encryptedText) =>
      encryptedText.startsWith('$prefix:')
          ? encryptedText.substring(prefix.length + 1)
          : 'ERRO_DECRIPT';

  @override
  String encryptData(String plainText) => '$prefix:$plainText';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupCodec & Fixtures Round-trip', () {
    test('L11: Round-trip preserves unknown fields, maps, lists, and nanosecond timestamps', () {
      final rawDoc = LegacyFixtures.l11['rawDoc'] as Map<String, dynamic>;
      final record = BackupRecord(
        id: rawDoc['id'].toString(),
        data: Map<String, dynamic>.from(rawDoc),
      );

      final encodedJson = BackupCodec.encodeRecords([record]);
      final decodedList = BackupCodec.decodeRecords(encodedJson);

      expect(decodedList.length, equals(1));
      final decoded = decodedList.first;
      expect(decoded.id, equals('doc_unknown_fields'));
      expect(decoded.data['legacyExtraFlag'], isTrue);
      expect(decoded.data['nestedMetadata']['importedFrom'], equals('old_app_v1'));
      expect(decoded.data['nestedMetadata']['tags'], equals(['sync', 'imported']));
      expect(decoded.data['amount'], equals(123.45));

      final exactCreated = decoded.data['exactCreated'] as Map<String, dynamic>;
      expect(exactCreated['_seconds'], equals(1711966830));
      expect(exactCreated['_nanoseconds'], equals(987654321));

      final digest1 = BackupCodec.computeCanonicalDigest(rawDoc);
      final digest2 = BackupCodec.computeCanonicalDigest(decoded.data);
      expect(digest1, equals(digest2));
    });

    test('Canonicalizes maps with deterministic key ordering', () {
      final map1 = {'z': 1, 'a': 2, 'm': {'k': 10, 'b': 20}};
      final map2 = {'a': 2, 'm': {'b': 20, 'k': 10}, 'z': 1};

      final digest1 = BackupCodec.computeCanonicalDigest(map1);
      final digest2 = BackupCodec.computeCanonicalDigest(map2);

      expect(digest1, equals(digest2));
    });

    test('Rejects unsupported types with descriptive exception', () {
      final invalidMap = {
        'id': 'bad_doc',
        'invalidObject': Stopwatch(),
      };

      expect(
        () => BackupCodec.canonicalizeValue(invalidMap, recordId: 'bad_doc'),
        throwsA(isA<BackupCodecException>()),
      );
    });
  });

  group('BackupCrypto Envelope & Security', () {
    const testPassword = 'MySecurePassword123!';
    final sampleZipPayload = Uint8List.fromList(
      utf8.encode('Sample ZIP archive payload contents for test'),
    );

    test('Encrypts and decrypts envelope successfully', () {
      final envelope = BackupCrypto.encryptEnvelope(
        payload: sampleZipPayload,
        password: testPassword,
        iterations: 10000,
      );

      expect(envelope.length, greaterThan(sampleZipPayload.length));

      expect(envelope.sublist(0, 4), equals(BackupCrypto.magicBytes));

      final decrypted = BackupCrypto.decryptEnvelope(
        envelope: envelope,
        password: testPassword,
      );

      expect(decrypted, equals(sampleZipPayload));
    });

    test('Rejects wrong password without decrypting', () {
      final envelope = BackupCrypto.encryptEnvelope(
        payload: sampleZipPayload,
        password: testPassword,
        iterations: 10000,
      );

      expect(
        () => BackupCrypto.decryptEnvelope(
          envelope: envelope,
          password: 'WrongPassword999!',
        ),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('Rejects truncated or corrupted envelope', () {
      final envelope = BackupCrypto.encryptEnvelope(
        payload: sampleZipPayload,
        password: testPassword,
        iterations: 10000,
      );

      final truncated = envelope.sublist(0, envelope.length - 10);
      expect(
        () => BackupCrypto.decryptEnvelope(
          envelope: truncated,
          password: testPassword,
        ),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('Rejects future format version', () {
      final envelope = BackupCrypto.encryptEnvelope(
        payload: sampleZipPayload,
        password: testPassword,
        iterations: 10000,
      );

      final altered = Uint8List.fromList(envelope);
      final byteData = ByteData.sublistView(altered);
      byteData.setUint16(4, 99, Endian.big);

      expect(
        () => BackupCrypto.decryptEnvelope(
          envelope: altered,
          password: testPassword,
        ),
        throwsA(isA<BackupCryptoException>()),
      );
    });

    test('Zip unpack rejects path traversal and dangerous paths', () {
      final files = {
        '../../evil.sh': utf8.encode('echo hack'),
      };
      final zipBytes = BackupCrypto.packArchive(files);

      expect(
        () => BackupCrypto.unpackArchive(zipBytes),
        throwsA(isA<BackupSecurityException>()),
      );
    });

    test('Zip unpack rejects absolute paths', () {
      final files = {
        '/etc/passwd': utf8.encode('root:x:0:0:root:/root:/bin/bash'),
      };
      final zipBytes = BackupCrypto.packArchive(files);

      expect(
        () => BackupCrypto.unpackArchive(zipBytes),
        throwsA(isA<BackupSecurityException>()),
      );
    });
  });

  group('End-to-End Backup and Resumable Restore', () {
    late MemoryRawStorage sourceStorage;
    late MemoryRawStorage targetStorage;
    late SessionContext sessionContext;
    late TestAppClock testClock;
    late FakeSecureStorage fakeSecureStorage;
    const testUid = 'user_test_123';
    const backupPassword = 'StrongPassword!2026';

    setUp(() {
      sourceStorage = MemoryRawStorage();
      targetStorage = MemoryRawStorage();
      fakeSecureStorage = FakeSecureStorage();
      sessionContext = const SessionContext(
        userId: testUid,
        sessionGeneration: 1,
      );
      testClock = TestAppClock(DateTime.utc(2026, 9, 20, 15, 0, 0));

      sourceStorage.documents['users/$testUid/categories/cat_food'] = {
        'id': 'cat_food',
        'name': 'Alimentação',
        'color': 4283215696,
        'icon': 'restaurant',
      };
      sourceStorage.documents['users/$testUid/categories/cat_bills'] = {
        'id': 'cat_bills',
        'name': 'Contas Fixas',
        'color': 4294198070,
        'icon': 'receipt',
      };

      sourceStorage.documents['users/$testUid/folders/fld_finance'] = {
        'id': 'fld_finance',
        'name': 'Bancos & Cartões',
        'color': 4288585374,
      };

      sourceStorage.documents['users/$testUid/expenses/exp_001'] = {
        'id': 'exp_001',
        'amount': 150.0,
        'date': '2026-09-20T12:00:00.000',
        'categoryId': 'cat_bills',
        'motivation': 'Conta de Luz',
        'recurringExpenseId': 'rec_001',
        'isIncome': false,
      };
      sourceStorage.documents['users/$testUid/expenses/exp_inst_1'] = {
        'id': 'exp_inst_1',
        'amount': 33.333333333333336,
        'date': '2026-09-21T10:00:00.000',
        'currentInstallment': 1,
        'totalInstallments': 3,
        'installmentGroupId': 'grp_laptop',
      };

      sourceStorage.documents['users/$testUid/recurring_expenses/rec_001'] = {
        'id': 'rec_001',
        'amount': 150.0,
        'categoryId': 'cat_bills',
        'motivation': 'Conta de Luz Recorrente',
        'frequency': 'monthly',
        'dayOfMonth': 20,
        'lastInstanceDate': {
          '_type': 'timestamp',
          '_seconds': 1790000000,
          '_nanoseconds': 0,
        },
        'advanceGenerationCount': 0,
      };

      sourceStorage.documents['users/$testUid/suppliers/sup_001'] = {
        'id': 'sup_001',
        'name': 'Companhia Elétrica',
        'email': 'contato@eletrica.com',
        'notes': 'Atendimento 24h',
      };
    });

    test('restores a legacy credential using the destination encryption key', () async {
      sourceStorage.documents['users/$testUid/credentials/legacy'] = {
        'id': 'legacy',
        'location': 'example.org',
        'login': 'user',
        'encrypted_password': 'old-key:secret',
      };
      final backup = await BackupService(
        rawReader: sourceStorage,
        sessionContext: sessionContext,
        clock: testClock,
        encryptionService: _CredentialCipher('old-key'),
      ).createBackup(password: backupPassword);
      expect(backup.isSuccess, isTrue);
      expect(backup.data?.completeness.isComplete, isTrue);

      final restore = RestoreService(
        rawReader: targetStorage,
        rawWriter: targetStorage,
        sessionContext: sessionContext,
        encryptionService: _CredentialCipher('new-key'),
        clock: testClock,
        secureStorage: fakeSecureStorage,
      );
      final preview = await restore.previewRestore(
        backupBytes: backup.data!.envelopeBytes,
        password: backupPassword,
      );
      expect(preview.isSuccess, isTrue);
      final result = await restore.executeRestore(
        plan: preview.data!,
        backupBytes: backup.data!.envelopeBytes,
        password: backupPassword,
      );
      expect(result.isSuccess, isTrue);
      expect(
        targetStorage.documents['users/$testUid/credentials/legacy']?['encrypted_password'],
        'new-key:secret',
      );
    });

    test('Creates verifiable backup with self-verification', () async {
      final backupService = BackupService(
        rawReader: sourceStorage,
        sessionContext: sessionContext,
        clock: testClock,
      );

      final result = await backupService.createBackup(
        password: backupPassword,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      final backupData = result.data!;

      expect(backupData.manifest.formatVersion, equals(1));
      expect(backupData.manifest.originUid, equals(testUid));
      expect(backupData.manifest.counts['categories'], equals(2));
      expect(backupData.manifest.counts['folders'], equals(1));
      expect(backupData.manifest.counts['expenses'], equals(2));
      expect(backupData.manifest.counts['recurring_expenses'], equals(1));
      expect(backupData.manifest.counts['suppliers'], equals(1));
      expect(backupData.completeness.isComplete, isTrue);
    });

    test('Dry-run preview performs ZERO writes to target database', () async {
      final backupService = BackupService(
        rawReader: sourceStorage,
        sessionContext: sessionContext,
        clock: testClock,
      );
      final backupRes = await backupService.createBackup(
        password: backupPassword,
      );
      final backupBytes = backupRes.data!.envelopeBytes;

      final restoreService = RestoreService(
        rawReader: targetStorage,
        rawWriter: targetStorage,
        sessionContext: sessionContext,
        clock: testClock,
        secureStorage: fakeSecureStorage,
      );

      final previewRes = await restoreService.previewRestore(
        backupBytes: backupBytes,
        password: backupPassword,
      );

      expect(previewRes.isSuccess, isTrue);
      final plan = previewRes.data!;
      expect(plan.isUidMatched, isTrue);
      expect(plan.canExecute, isTrue);
      expect(plan.createCount, equals(7));
      expect(plan.conflictCount, equals(0));
      expect(plan.skipCount, equals(0));

      expect(targetStorage.documents.isEmpty, isTrue);
    });

    test('Full restore reproduces all records identically and supports idempotency', () async {
      final backupService = BackupService(
        rawReader: sourceStorage,
        sessionContext: sessionContext,
        clock: testClock,
      );
      final backupRes = await backupService.createBackup(
        password: backupPassword,
      );
      final backupBytes = backupRes.data!.envelopeBytes;

      final restoreService = RestoreService(
        rawReader: targetStorage,
        rawWriter: targetStorage,
        sessionContext: sessionContext,
        clock: testClock,
        secureStorage: fakeSecureStorage,
      );

      final previewRes = await restoreService.previewRestore(
        backupBytes: backupBytes,
        password: backupPassword,
      );
      final plan = previewRes.data!;

      final execRes = await restoreService.executeRestore(
        plan: plan,
        backupBytes: backupBytes,
        password: backupPassword,
      );

      expect(execRes.isSuccess, isTrue);
      final summary = execRes.data!;
      expect(summary.createdCount, equals(7));
      expect(summary.replacedCount, equals(0));

      expect(targetStorage.documents.containsKey('users/$testUid/categories/cat_food'), isTrue);
      expect(targetStorage.documents.containsKey('users/$testUid/expenses/exp_001'), isTrue);
      final expDoc = targetStorage.documents['users/$testUid/expenses/exp_001']!;
      expect(expDoc['amount'], equals(150.0));
      expect(expDoc['recurringExpenseId'], equals('rec_001'));

      final instDoc = targetStorage.documents['users/$testUid/expenses/exp_inst_1']!;
      expect(instDoc['amount'], equals(33.333333333333336));

      final secondPreview = await restoreService.previewRestore(
        backupBytes: backupBytes,
        password: backupPassword,
      );
      final plan2 = secondPreview.data!;
      expect(plan2.createCount, equals(0));
      expect(plan2.conflictCount, equals(0));
      expect(plan2.skipCount, equals(7));

      final secondExec = await restoreService.executeRestore(
        plan: plan2,
        backupBytes: backupBytes,
        password: backupPassword,
      );
      expect(secondExec.isSuccess, isTrue);
      expect(secondExec.data!.createdCount, equals(0));
      expect(secondExec.data!.skippedCount, equals(7));
    });

    test('Conflict detection detects differences and default keepTarget protects data', () async {

      final backupService = BackupService(
        rawReader: sourceStorage,
        sessionContext: sessionContext,
        clock: testClock,
      );
      final backupRes = await backupService.createBackup(
        password: backupPassword,
      );
      final backupBytes = backupRes.data!.envelopeBytes;

      targetStorage.documents['users/$testUid/expenses/exp_001'] = {
        'id': 'exp_001',
        'amount': 200.0,
        'date': '2026-09-20T12:00:00.000',
        'categoryId': 'cat_bills',
      };

      final restoreService = RestoreService(
        rawReader: targetStorage,
        rawWriter: targetStorage,
        sessionContext: sessionContext,
        clock: testClock,
        secureStorage: fakeSecureStorage,
      );

      final previewRes = await restoreService.previewRestore(
        backupBytes: backupBytes,
        password: backupPassword,
      );

      final plan = previewRes.data!;
      expect(plan.conflictCount, equals(1));
      final conflictItem = plan.items.firstWhere((i) => i.action == ImportAction.conflict);
      expect(conflictItem.documentId, equals('exp_001'));

      expect(conflictItem.resolution, equals(ConflictResolution.keepTarget));
      expect(conflictItem.willWrite, isFalse);

      await restoreService.executeRestore(
        plan: plan,
        backupBytes: backupBytes,
        password: backupPassword,
      );

      expect(
        targetStorage.documents['users/$testUid/expenses/exp_001']!['amount'],
        equals(200.0),
      );
    });

    test('Rejects restore if originUid does not match destination sessionContext', () async {
      final backupService = BackupService(
        rawReader: sourceStorage,
        sessionContext: sessionContext,
        clock: testClock,
      );
      final backupRes = await backupService.createBackup(
        password: backupPassword,
      );
      final backupBytes = backupRes.data!.envelopeBytes;

      final differentSession = const SessionContext(
        userId: 'other_hacker_user_456',
        sessionGeneration: 1,
      );
      final restoreService = RestoreService(
        rawReader: targetStorage,
        rawWriter: targetStorage,
        sessionContext: differentSession,
        clock: testClock,
        secureStorage: fakeSecureStorage,
      );

      final previewRes = await restoreService.previewRestore(
        backupBytes: backupBytes,
        password: backupPassword,
      );

      expect(previewRes.isSuccess, isFalse);
      expect(previewRes.safeError, contains('A restauração na v1 só é permitida na mesma conta de origem'));
    });

    test('Rollback compensation removes created documents safely', () async {
      final journal = OperationJournal(
        operationId: 'op_test_rollback',
        uid: testUid,
      );

      targetStorage.documents['users/$testUid/categories/temp_cat'] = {
        'id': 'temp_cat',
        'name': 'Temporária',
      };
      journal.recordCommit('categories', 'temp_cat', isCreate: true);

      final restoreService = RestoreService(
        rawReader: targetStorage,
        rawWriter: targetStorage,
        sessionContext: sessionContext,
        clock: testClock,
        secureStorage: fakeSecureStorage,
      );

      final rollbackRes = await restoreService.rollbackOperation(journal: journal);
      expect(rollbackRes.isSuccess, isTrue);
      expect(rollbackRes.data, equals(1));
      expect(targetStorage.documents.containsKey('users/$testUid/categories/temp_cat'), isFalse);
    });
  });
}
