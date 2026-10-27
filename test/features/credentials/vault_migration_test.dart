import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/security/vault_crypto.dart';
import 'package:key_budget/core/security/vault_key_repository.dart';
import 'package:key_budget/features/credentials/application/vault_migration_service.dart';
import '../../core/security/memory_vault_store.dart';

const _key = '12345678901234567890123456789012';

String _legacy(String plaintext) {
  final iv = legacy.IV.fromLength(16);
  return '${iv.base64}:${legacy.Encrypter(legacy.AES(legacy.Key.fromUtf8(_key))).encrypt(plaintext, iv: iv).base64}';
}

MemoryVaultStore _store() {
  final store = MemoryVaultStore();
  store.documents['users/a/credentials/one'] = {
    'login': 'owner',
    'encrypted_password': _legacy('ERRO_DECRIPT'),
  };
  store.documents['users/a/credentials/two'] = {
    'location': 'Two',
    'encrypted_password': _legacy('á🔑'),
  };
  store.documents['users/a/trash/deleted'] = {
    'collection': 'credentials',
    'deletedAt': Timestamp.fromMillisecondsSinceEpoch(1234),
    'records': [
      {
        'id': 'three',
        'data': {'location': 'Trash', 'encrypted_password': _legacy('secret')},
      },
    ],
  };
  return store;
}

void main() {
  test('preview and unconfirmed attempts never write', () async {
    final store = _store();
    final service = VaultMigrationService(store: store, uid: 'a');
    final preview = await service.preview('  $_key\n');
    expect(preview.entries.length, 3);
    expect(preview.entries.where((p) => p.inTrash).length, 1);
    expect(preview.canProceed, isTrue);
    expect(store.writes, 0);
    await expectLater(
      service.start(preview, confirmed: false),
      throwsA(isA<VaultException>()),
    );
    service.discardPreview();
    expect(store.writes, 0);
  });

  test(
    'invalid legacy keys and malformed records cannot start migration',
    () async {
      final store = _store();
      final service = VaultMigrationService(store: store, uid: 'a');
      final preview = await service.preview('a' * 32);
      expect(preview.canProceed, isFalse);
      await expectLater(
        service.start(preview, confirmed: true),
        throwsA(isA<VaultException>()),
      );
      expect(store.writes, 0);
      store.documents['users/a/credentials/broken'] = {
        'location': 'Missing password',
      };
      await expectLater(service.preview(_key), throwsA(isA<VaultException>()));
      expect(store.writes, 0);
    },
  );

  test(
    'migration survives process interruption without saving legacy key',
    () async {
      final store = _store();
      final service = VaultMigrationService(store: store, uid: 'a');
      final preview = await service.preview(_key);
      store.failSourceWriteAt = 1;
      await expectLater(
        service.start(preview, confirmed: true),
        throwsStateError,
      );
      final config = store.documents['users/a/vault/config']!;
      final id = config['migrationId'] as String;
      final job = store.documents['users/a/vault_migrations/$id']!;
      expect(job['backupVerifiedAt'], isNotNull);
      expect(store.sourceWrites, 1);
      expect(
        jsonEncode(
          store.documents,
          toEncodable: (o) => o is Blob ? base64.encode(o.bytes) : o.toString(),
        ),
        isNot(contains(_key)),
      );
      store.failSourceWriteAt = null;
      await VaultMigrationService(store: store, uid: 'a').resume(id);
      expect(store.documents['users/a/vault/config']!['state'], 'ready');
      final key = await VaultKeyRepository(
        store,
      ).load('a', config['activeKeyId'] as String);
      final cipher = key.cipher();
      expect(
        cipher.decrypt(
          store.documents['users/a/credentials/one']!['encrypted_password']
              as String,
          uid: 'a',
          recordId: 'one',
        ),
        'ERRO_DECRIPT',
      );
      final trash = store.documents['users/a/trash/deleted']!;
      final encrypted =
          ((trash['records'] as List).single['data']
                  as Map)['encrypted_password']
              as String;
      expect(cipher.decrypt(encrypted, uid: 'a', recordId: 'three'), 'secret');
      expect(store.sourceWrites, 3);
      await VaultMigrationService(store: store, uid: 'a').rollback(id);
      expect(store.documents['users/a/vault/config']!['state'], 'rolledBack');
      expect(
        LegacyVaultReader(_key).decrypt(
          store.documents['users/a/credentials/one']!['encrypted_password']
              as String,
        ),
        'ERRO_DECRIPT',
      );
      await VaultMigrationService(store: store, uid: 'a').resume(id);
      expect(store.documents['users/a/vault/config']!['state'], 'ready');
    },
  );

  test('unreadable durable backup prevents all source replacements', () async {
    final store = _store();
    final service = VaultMigrationService(store: store, uid: 'a');
    final preview = await service.preview(_key);
    var setFailure = false;
    await expectLater(
      service.start(
        preview,
        confirmed: true,
        onProgress: (_, _, _) {
          if (!setFailure) {
            setFailure = true;
            final id = store.documents['users/a/vault/config']!['migrationId'];
            store.failReadPath = 'users/a/vault_migrations/$id';
          }
        },
      ),
      throwsStateError,
    );
    expect(store.sourceWrites, 0);
  });

  test(
    'changed documents are not overwritten by migration or rollback',
    () async {
      final store = _store();
      final service = VaultMigrationService(store: store, uid: 'a');
      final preview = await service.preview(_key);
      store.documents['users/a/credentials/one']!['login'] = 'changed';
      await expectLater(
        service.start(preview, confirmed: true),
        throwsA(isA<VaultException>()),
      );
      expect(store.writes, 0);
      final updated = await service.preview(_key);
      await service.start(updated, confirmed: true);
      final id =
          store.documents['users/a/vault/config']!['migrationId'] as String;
      store.documents['users/a/credentials/one']!['login'] =
          'edited after migration';
      await expectLater(service.rollback(id), throwsA(isA<VaultException>()));
      expect(
        store.documents['users/a/credentials/one']!['login'],
        'edited after migration',
      );
    },
  );
}
