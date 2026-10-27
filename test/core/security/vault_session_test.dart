import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../helpers/memory_secure_storage.dart';
import 'package:key_budget/core/security/vault_session.dart';
import 'package:key_budget/core/security/vault_key_repository.dart';
import 'memory_vault_store.dart';

class _DelayedStore extends MemoryVaultStore {
  final gate = Completer<void>();
  @override
  Future<Map<String, dynamic>?> read(String path) async {
    if (path == 'users/first/vault/config') await gate.future;
    return super.read(path);
  }
}

class _OfflineStore extends MemoryVaultStore {
  bool offline = false;
  String? unavailablePath;
  @override
  Future<Map<String, dynamic>?> read(String path) {
    if (offline || path == unavailablePath) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    return super.read(path);
  }
}

void main() {
  test('recovery invalidates cached access before attempting writes', () async {
    final store = _OfflineStore();
    final cache = MemorySecureStorage();
    final session = VaultSession(store: store, secureStorage: cache);
    await session.open('owner');
    expect(cache.values, isNotEmpty);
    final writes = store.writes;
    await expectLater(
      session.migrationService().resume('missing'),
      throwsA(isA<Exception>()),
    );
    expect(session.canWrite, isFalse);
    expect(cache.values, isEmpty);
    expect(store.writes, writes);
    store.offline = true;
    await session.open('owner');
    expect(session.status, VaultStatus.unavailable);
    session.dispose();
  });

  test('known remote recovery cannot fall back to a ready cache', () async {
    final store = _OfflineStore();
    final cache = MemorySecureStorage();
    final session = VaultSession(store: store, secureStorage: cache);
    await session.open('owner');
    final config = store.documents['users/owner/vault/config']!;
    config['state'] = 'rollingBack';
    config['migrationId'] = 'operation';
    store.unavailablePath = 'users/owner/vault_migrations/operation';
    await session.open('owner');
    expect(session.canWrite, isFalse);
    expect(session.status, VaultStatus.unavailable);
    expect(cache.values, isEmpty);
    store.offline = true;
    await session.open('owner');
    expect(session.canWrite, isFalse);
    session.dispose();
  });

  test('cache deletion failure prevents migration writes', () async {
    final store = MemoryVaultStore();
    final cache = MemorySecureStorage();
    final session = VaultSession(store: store, secureStorage: cache);
    await session.open('owner');
    cache.failDeletes = true;
    final writes = store.writes;
    await expectLater(
      session.migrationService().resume('missing'),
      throwsStateError,
    );
    expect(store.writes, writes);
    expect(cache.values, isNotEmpty);
    session.dispose();
  });

  test(
    'verified local key opens offline but logout removes cached access',
    () async {
      final store = _OfflineStore();
      final cache = MemorySecureStorage();
      final session = VaultSession(store: store, secureStorage: cache);
      await session.open('owner');
      final value = session.encryption.encryptData(
        'offline-secret',
        recordId: 'one',
      );
      store.offline = true;
      await session.open('owner');
      expect(session.isReady, isTrue);
      expect(
        session.encryption.decryptData(value, recordId: 'one'),
        'offline-secret',
      );
      await session.open(null);
      expect(cache.values, isEmpty);
      await session.open('owner');
      expect(session.status, VaultStatus.unavailable);
      session.dispose();
    },
  );

  test('new accounts automatically receive stable individual keys', () async {
    final store = MemoryVaultStore();
    final session = VaultSession(store: store);
    await session.open('owner');
    expect(session.isReady, isTrue);
    expect(session.canImportLegacy, isFalse);
    final config = store.documents['users/owner/vault/config']!;
    final id = config['activeKeyId'];
    final encrypted = session.encryption.encryptData('test', recordId: 'one');
    await session.open(null);
    expect(session.status, VaultStatus.idle);
    await session.open('owner');
    expect(store.documents['users/owner/vault/config']!['activeKeyId'], id);
    expect(session.encryption.decryptData(encrypted, recordId: 'one'), 'test');
    session.dispose();
  });

  test('legacy account offers profile entry without creating keys', () async {
    final store = MemoryVaultStore();
    store.documents['users/owner/credentials/one'] = {
      'encrypted_password': 'iv:legacy',
    };
    final session = VaultSession(store: store);
    await session.open('owner');
    expect(session.canImportLegacy, isTrue);
    expect(session.canWrite, isFalse);
    expect(store.writes, 0);
    await VaultKeyRepository(store).ensure('owner', migrationId: 'operation');
    await session.open('owner');
    expect(session.hasVersionedKey, isTrue);
    expect(session.canImportLegacy, isFalse);
    expect(session.needsRecovery, isTrue);
    expect(session.hasVerifiedBackup, isFalse);
    session.dispose();
  });

  test(
    'late results from a previous account do not replace current keys',
    () async {
      final store = _DelayedStore();
      final session = VaultSession(store: store);
      final first = session.open('first');
      await session.open('second');
      store.gate.complete();
      await first;
      expect(session.userId, 'second');
      expect(session.isReady, isTrue);
      expect(
        store.documents.keys.where(
          (p) => p.contains('users/first/vault_keys/'),
        ),
        isEmpty,
      );
      session.dispose();
    },
  );

  test(
    'missing remote key does not offer legacy setup or replace it',
    () async {
      final store = MemoryVaultStore();
      final session = VaultSession(store: store);
      await session.open('owner');
      store.documents.removeWhere((path, _) => path.contains('/vault_keys/'));
      final writes = store.writes;
      await session.open('owner');
      expect(session.status, VaultStatus.unavailable);
      expect(session.canImportLegacy, isFalse);
      expect(store.writes, writes);
      session.dispose();
    },
  );
}
