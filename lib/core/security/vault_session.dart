import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/features/credentials/application/vault_migration_service.dart';
import 'vault_crypto.dart';
import 'vault_key_repository.dart';
import 'vault_store.dart';

enum VaultStatus {
  idle,
  loading,
  legacyRequired,
  ready,
  recoveryRequired,
  unavailable,
}

class VaultSession extends ChangeNotifier {
  final VaultStore store;
  final FlutterSecureStorage? secureStorage;
  VaultStatus status = VaultStatus.idle;
  String? userId;
  String? migrationId;
  String? migrationPhase;
  String? error;
  bool hasVerifiedBackup = false;
  bool hasVersionedKey = false;
  VaultKey? _key;
  VaultCipher? _cipher;
  int _generation = 0;
  bool _disposed = false;

  VaultSession({required this.store, this.secureStorage});

  bool get canImportLegacy =>
      status == VaultStatus.legacyRequired && !hasVersionedKey;
  bool get isRollingBack => migrationPhase == 'rollingBack';
  bool get needsRecovery => status == VaultStatus.recoveryRequired;
  bool get canWrite => status == VaultStatus.ready;
  bool get isReady => canWrite && _cipher != null;

  EncryptionService get encryption {
    if (!isReady) {
      throw const VaultException(
        VaultErrorCode.unavailable,
        'O cofre ainda não está pronto. Abra a proteção do cofre no perfil.',
      );
    }
    return EncryptionService(cipher: _cipher, userId: userId);
  }

  VaultCipher? get recoveryCipher => _cipher;

  bool _active(String uid, int generation) =>
      !_disposed && userId == uid && _generation == generation;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> open(String? uid) async {
    final previous = userId;
    final generation = ++_generation;
    _cipher?.dispose();
    _key?.dispose();
    _cipher = null;
    _key = null;
    userId = uid;
    migrationId = null;
    migrationPhase = null;
    hasVersionedKey = false;
    hasVerifiedBackup = false;
    error = null;
    status = uid == null ? VaultStatus.idle : VaultStatus.loading;
    _notify();
    if (previous != null && previous != uid) {
      try {
        await secureStorage?.delete(key: 'vault.session.$previous');
      } catch (_) {}
    }
    if (uid == null || !_active(uid, generation)) return;
    VaultKey? loadedKey;
    try {
      final repository = VaultKeyRepository(store);
      var config = await store.read(repository.configPath(uid));
      if (!_active(uid, generation)) return;
      if (config == null) {
        final inventory = await VaultInventory.capture(store, uid);
        if (!_active(uid, generation)) return;
        if (inventory.sources.isNotEmpty) {
          if (!inventory.hasLegacy) {
            throw const VaultException(
              VaultErrorCode.unknownKey,
              'Há senhas versionadas sem configuração de chave. Recupere o cofre.',
            );
          }
          status = VaultStatus.legacyRequired;
          _notify();
          return;
        }
        loadedKey = await repository.ensure(uid);
        config = await store.read(repository.configPath(uid));
      }
      if (!_active(uid, generation)) {
        loadedKey?.dispose();
        return;
      }
      if (config == null ||
          config['schemaVersion'] != 1 ||
          config['writeFormatVersion'] != 2 ||
          config['activeKeyId'] is! String) {
        throw const VaultException(
          VaultErrorCode.unknownKey,
          'Configuração do cofre inválida. Tente recuperar o acesso.',
        );
      }
      loadedKey ??= await repository.load(uid, config['activeKeyId'] as String);
      if (!_active(uid, generation)) {
        loadedKey.dispose();
        return;
      }
      _key = loadedKey;
      _cipher = loadedKey.cipher();
      hasVersionedKey = true;
      migrationId = config['migrationId'] as String?;
      migrationPhase = config['state'] as String?;
      status = config['state'] == 'ready'
          ? VaultStatus.ready
          : VaultStatus.recoveryRequired;
      if (status == VaultStatus.ready && migrationId != null) {
        hasVerifiedBackup = config['legacyMigrationCompletedAt'] != null;
      }
      if (migrationId != null && needsRecovery) {
        final job = await store.read(
          'users/$uid/vault_migrations/$migrationId',
        );
        if (!_active(uid, generation)) return;
        hasVerifiedBackup = job?['backupVerifiedAt'] != null;
      }
      if (status == VaultStatus.ready) {
        try {
          await secureStorage?.write(
            key: 'vault.session.$uid',
            value: jsonEncode({
              'uid': uid,
              'keyId': loadedKey.id,
              'key': loadedKey.toMap(),
            }),
          );
          if (!_active(uid, generation)) {
            await secureStorage?.delete(key: 'vault.session.$uid');
          }
        } catch (_) {}
      }
    } catch (exception) {
      loadedKey?.dispose();
      if (!_active(uid, generation)) return;
      _key = null;
      _cipher?.dispose();
      _cipher = null;
      if (exception is FirebaseException &&
          {
            'unavailable',
            'deadline-exceeded',
            'network-request-failed',
          }.contains(exception.code) &&
          await _restoreOffline(uid, generation)) {
        if (_active(uid, generation)) _notify();
        return;
      }
      if (!_active(uid, generation)) return;
      status = VaultStatus.unavailable;
      error = exception is VaultException
          ? exception.message
          : 'Não foi possível abrir o cofre. Confira sua conexão e tente novamente.';
    }
    if (_active(uid, generation)) _notify();
  }

  Future<bool> _restoreOffline(String uid, int generation) async {
    try {
      final cached = await secureStorage?.read(key: 'vault.session.$uid');
      if (cached == null || !_active(uid, generation)) return false;
      final data = jsonDecode(cached) as Map<String, dynamic>;
      if (data['uid'] != uid) return false;
      final key = VaultKey.fromMap(
        data['keyId'] as String,
        Map<String, dynamic>.from(data['key'] as Map),
      );
      _key = key;
      _cipher = key.cipher();
      hasVersionedKey = true;
      status = VaultStatus.ready;
      return true;
    } catch (_) {
      return false;
    }
  }

  VaultMigrationService migrationService() {
    final uid = userId;
    final generation = _generation;
    if (uid == null) {
      throw const VaultException(
        VaultErrorCode.unavailable,
        'Entre na sua conta para abrir o cofre.',
      );
    }
    return VaultMigrationService(
      store: store,
      uid: uid,
      isSessionActive: () => _active(uid, generation),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _cipher?.dispose();
    _key?.dispose();
    super.dispose();
  }
}

final vaultSessionProvider = ChangeNotifierProvider<VaultSession>(
  (ref) => VaultSession(
    store: FirestoreVaultStore(),
    secureStorage: const FlutterSecureStorage(),
  ),
);
