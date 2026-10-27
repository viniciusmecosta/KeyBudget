import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/import_export/backup_service.dart';
import 'package:key_budget/core/import_export/raw_storage.dart';
import 'package:key_budget/core/import_export/restore_service.dart';
import 'package:key_budget/core/operations/session_context.dart';
import 'package:key_budget/core/security/vault_crypto.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import '../../helpers/memory_secure_storage.dart';

void main() {
  const uid = 'owner';
  const context = SessionContext(userId: uid, sessionGeneration: 1);
  const password = 'synthetic-backup-password';

  test('active and trashed passwords restore using destination key', () async {
    final sourceCipher = EncryptionService(
      userId: uid,
      cipher: VaultCipher(keyId: 'source', key: List.filled(32, 1)),
    );
    final targetCipher = EncryptionService(
      userId: uid,
      cipher: VaultCipher(keyId: 'destination', key: List.filled(32, 2)),
    );
    final source = MemoryRawStorage();
    final target = MemoryRawStorage();
    source.documents['users/$uid/credentials/one'] = {
      'location': 'Portal',
      'login': 'login',
      'encrypted_password': sourceCipher.encryptData(
        'ERRO_DECRIPT',
        recordId: 'one',
      ),
    };
    source.documents['users/$uid/trash/deleted'] = {
      'collection': 'credentials',
      'deletedAt': Timestamp.fromMillisecondsSinceEpoch(123),
      'records': [
        {
          'id': 'three',
          'data': {
            'location': 'Trash',
            'encrypted_password': sourceCipher.encryptData(
              'secret-🔑',
              recordId: 'three',
            ),
          },
        },
      ],
    };
    final backup =
        await BackupService(
          rawReader: source,
          sessionContext: context,
          encryptionService: sourceCipher,
        ).createBackup(
          password: password,
          selectedModules: ['credentials', 'trash'],
        );
    expect(backup.data!.completeness.isComplete, isTrue);
    final restore = RestoreService(
      rawReader: target,
      rawWriter: target,
      sessionContext: context,
      encryptionService: targetCipher,
      secureStorage: MemorySecureStorage(),
    );
    final preview = await restore.previewRestore(
      backupBytes: backup.data!.envelopeBytes,
      password: password,
    );
    expect(preview.data!.canExecute, isTrue);
    expect(preview.data!.requiresLegacyPasswordReview, isFalse);
    expect(target.documents, isEmpty);
    final result = await restore.executeRestore(
      plan: preview.data!,
      backupBytes: backup.data!.envelopeBytes,
      password: password,
    );
    expect(result.isSuccess, isTrue);
    expect(
      targetCipher.decryptData(
        target.documents['users/$uid/credentials/one']!['encrypted_password']
            as String,
        recordId: 'one',
      ),
      'ERRO_DECRIPT',
    );
    final record =
        (target.documents['users/$uid/trash/deleted']!['records'] as List)
            .single;
    expect(
      targetCipher.decryptData(
        record['data']['encrypted_password'] as String,
        recordId: 'three',
      ),
      'secret-🔑',
    );
  });

  test(
    'legacy backup requires temporary key and explicit password review',
    () async {
      const key = '12345678901234567890123456789012';
      final iv = legacy.IV.allZerosOfLength(16);
      final encrypted = legacy.Encrypter(
        legacy.AES(legacy.Key.fromUtf8(key)),
      ).encrypt('old-secret', iv: iv);
      final source = MemoryRawStorage();
      final target = MemoryRawStorage();
      source.documents['users/$uid/credentials/old'] = {
        'location': 'Legacy',
        'encrypted_password': '${iv.base64}:${encrypted.base64}',
      };
      final backup = await BackupService(
        rawReader: source,
        sessionContext: context,
      ).createBackup(password: password, selectedModules: ['credentials']);
      final cipher = EncryptionService(
        userId: uid,
        cipher: VaultCipher(keyId: 'destination', key: List.filled(32, 2)),
      );
      final restore = RestoreService(
        rawReader: target,
        rawWriter: target,
        sessionContext: context,
        encryptionService: cipher,
        secureStorage: MemorySecureStorage(),
      );
      final withoutKey = await restore.previewRestore(
        backupBytes: backup.data!.envelopeBytes,
        password: password,
      );
      expect(withoutKey.data!.canExecute, isFalse);
      final preview = await restore.previewRestore(
        backupBytes: backup.data!.envelopeBytes,
        password: password,
        legacyKey: ' $key\n',
      );
      expect(preview.data!.canExecute, isTrue);
      expect(preview.data!.requiresLegacyPasswordReview, isTrue);
      final refused = await restore.executeRestore(
        plan: preview.data!,
        backupBytes: backup.data!.envelopeBytes,
        password: password,
      );
      expect(refused.isSuccess, isFalse);
      expect(target.documents, isEmpty);
      final restored = await restore.executeRestore(
        plan: preview.data!,
        backupBytes: backup.data!.envelopeBytes,
        password: password,
        legacyPasswordsReviewed: true,
      );
      expect(restored.isSuccess, isTrue);
      expect(
        cipher.decryptData(
          target.documents['users/$uid/credentials/old']!['encrypted_password']
              as String,
          recordId: 'old',
        ),
        'old-secret',
      );
    },
  );
}
