import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/security/vault_crypto.dart';
import 'package:passfin/core/security/vault_key_repository.dart';
import 'package:passfin/features/credentials/application/vault_migration_service.dart';
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
  test('legacy IVs beginning with kbv remain readable', () async {
    final store = MemoryVaultStore();
    final iv = legacy.IV(base64.decode('kbv${'A' * 19}=='));
    final encrypted = legacy.Encrypter(
      legacy.AES(legacy.Key.fromUtf8(_key)),
    ).encrypt('legacy-prefix-password', iv: iv);
    store.documents['users/a/credentials/one'] = {
      'encrypted_password': '${iv.base64}:${encrypted.base64}',
    };
    final inventory = await VaultInventory.capture(store, 'a');
    expect(inventory.hasLegacy, isTrue);
    final service = VaultMigrationService(store: store, uid: 'a');
    final preview = await service.preview(_key);
    expect(preview.canProceed, isTrue);
    expect(preview.entries.single.plaintext, 'legacy-prefix-password');
    await service.start(preview, confirmed: true);
    expect(store.documents['users/a/vault/config']!['state'], 'ready');
  });

  test('verified backups cannot be replaced by a new legacy attempt', () async {
    final store = _store();
    final service = VaultMigrationService(store: store, uid: 'a');
    await service.start(await service.preview(_key), confirmed: true);
    final id =
        store.documents['users/a/vault/config']!['migrationId'] as String;
    await service.rollback(id);
    final checkpoint = copyVaultMap(store.documents);
    final writes = store.writes;
    final retry = VaultMigrationService(store: store, uid: 'a');
    await expectLater(
      retry.start(await retry.preview(_key), confirmed: true),
      throwsA(isA<VaultException>()),
    );
    expect(store.writes, writes);
    expect(store.documents, checkpoint);
    await retry.resume(id);
    expect(store.documents['users/a/vault/config']!['state'], 'ready');
  });

  test('every durable write boundary can be interrupted and recovered', () async {
    final baseline = _store();
    final completed = VaultMigrationService(store: baseline, uid: 'a');
    await completed.start(await completed.preview(_key), confirmed: true);
    final boundaries = baseline.writes;
    for (var boundary = 0; boundary < boundaries; boundary++) {
      final store = _store();
      final originals = await VaultInventory.capture(store, 'a');
      final service = VaultMigrationService(store: store, uid: 'a');
      final preview = await service.preview(_key);
      store.failWriteAt = boundary;
      await expectLater(
        service.start(preview, confirmed: true),
        throwsStateError,
        reason: 'write boundary $boundary',
      );
      final config = store.documents['users/a/vault/config'];
      final id = config?['migrationId'] as String?;
      final verified =
          id != null &&
          store.documents['users/a/vault_migrations/$id']?['backupVerifiedAt'] !=
              null;
      final recovery = VaultMigrationService(store: store, uid: 'a');
      store.failWriteAt = null;
      if (verified) {
        await recovery.resume(id);
      } else {
        expect(store.sourceWrites, 0, reason: 'write boundary $boundary');
        expect(
          (await VaultInventory.capture(store, 'a')).digest,
          originals.digest,
        );
        await recovery.start(await recovery.preview(_key), confirmed: true);
      }
      final active = store.documents['users/a/vault/config']!;
      expect(active['state'], 'ready', reason: 'write boundary $boundary');
      final key = await VaultKeyRepository(
        store,
      ).load('a', active['activeKeyId'] as String);
      final cipher = key.cipher();
      final actual = await VaultInventory.capture(store, 'a');
      for (final source in actual.sources) {
        for (final password in source.passwords) {
          final original = originals.sources
              .firstWhere((s) => s.path == source.path)
              .passwords
              .firstWhere((p) => p.id == password.id);
          expect(
            cipher.decrypt(
              password.ciphertext,
              uid: 'a',
              recordId: password.id,
            ),
            LegacyVaultReader(_key).decrypt(original.ciphertext),
            reason: 'write boundary $boundary',
          );
        }
      }
      cipher.dispose();
      key.dispose();
      await recovery.rollback(active['migrationId'] as String);
      expect(
        (await VaultInventory.capture(store, 'a')).digest,
        originals.digest,
      );
    }
  });

  test(
    'every rollback write boundary preserves an exact recoverable original',
    () async {
      final baseline = _store();
      final completed = VaultMigrationService(store: baseline, uid: 'a');
      await completed.start(await completed.preview(_key), confirmed: true);
      final id =
          baseline.documents['users/a/vault/config']!['migrationId'] as String;
      final startWrites = baseline.writes;
      await completed.rollback(id);
      final boundaries = baseline.writes - startWrites;
      for (var boundary = 0; boundary < boundaries; boundary++) {
        final store = _store();
        final originals = await VaultInventory.capture(store, 'a');
        final service = VaultMigrationService(store: store, uid: 'a');
        await service.start(await service.preview(_key), confirmed: true);
        final id =
            store.documents['users/a/vault/config']!['migrationId'] as String;
        store.failWriteAt = store.writes + boundary;
        await expectLater(
          service.rollback(id),
          throwsStateError,
          reason: 'rollback write boundary $boundary',
        );
        store.failWriteAt = null;
        final recovery = VaultMigrationService(store: store, uid: 'a');
        await recovery.rollback(id);
        expect(
          (await VaultInventory.capture(store, 'a')).digest,
          originals.digest,
          reason: 'rollback write boundary $boundary',
        );
        expect(store.documents['users/a/vault/config']!['state'], 'rolledBack');
        await recovery.resume(id);
        expect(store.documents['users/a/vault/config']!['state'], 'ready');
      }
    },
  );

  test(
    'authenticated backup corruption blocks resume and rollback writes',
    () async {
      final store = _store();
      final service = VaultMigrationService(store: store, uid: 'a');
      await service.start(await service.preview(_key), confirmed: true);
      final id =
          store.documents['users/a/vault/config']!['migrationId'] as String;
      final job = store.documents['users/a/vault_migrations/$id']!;
      final generation = job['backupGeneration'];
      final path =
          'users/a/vault_migrations/$id/backup_chunks/$generation-000000';
      final chunk = store.documents[path]!;
      final bytes = Uint8List.fromList((chunk['bytes'] as Blob).bytes);
      bytes[bytes.length - 1] ^= 1;
      chunk['bytes'] = Blob(bytes);
      job['backupDigest'] = sha256.convert(bytes).toString();
      final writes = store.writes;
      await expectLater(service.resume(id), throwsA(isA<VaultException>()));
      await expectLater(service.rollback(id), throwsA(isA<VaultException>()));
      expect(store.writes, writes);
      expect(store.documents['users/a/vault/config']!['state'], 'ready');
      expect(store.documents[path], isNotNull);
    },
  );

  test(
    'logout stops subsequent writes and leaves a resumable backup',
    () async {
      final store = _store();
      var active = true;
      final service = VaultMigrationService(
        store: store,
        uid: 'a',
        isSessionActive: () => active,
      );
      final preview = await service.preview(_key);
      await expectLater(
        service.start(
          preview,
          confirmed: true,
          onProgress: (_, done, _) {
            if (done == 1) active = false;
          },
        ),
        throwsA(isA<VaultException>()),
      );
      expect(store.sourceWrites, 1);
      final id =
          store.documents['users/a/vault/config']!['migrationId'] as String;
      await VaultMigrationService(store: store, uid: 'a').resume(id);
      expect(store.documents['users/a/vault/config']!['state'], 'ready');
    },
  );

  test(
    'large vault migrates without relying on a single batch limit',
    () async {
      final store = MemoryVaultStore();
      final ciphertext = _legacy('large-vault');
      for (var i = 0; i < 650; i++) {
        store.documents['users/a/credentials/record-$i'] = {
          'encrypted_password': ciphertext,
        };
      }
      final service = VaultMigrationService(store: store, uid: 'a');
      final preview = await service.preview(_key);
      expect(preview.entries.length, 650);
      await service.start(preview, confirmed: true);
      expect(store.sourceWrites, 650);
      expect(store.documents['users/a/vault/config']!['state'], 'ready');
    },
  );

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
