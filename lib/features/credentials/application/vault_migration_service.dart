import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:key_budget/core/import_export/backup_codec.dart';
import 'package:key_budget/core/import_export/backup_crypto.dart';
import 'package:key_budget/core/security/vault_crypto.dart';
import 'package:key_budget/core/security/vault_key_repository.dart';
import 'package:key_budget/core/security/vault_store.dart';

String vaultDigest(Map<String, dynamic> value) =>
    BackupCodec.computeCanonicalDigest(value);

Map<String, dynamic> _copy(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(
      BackupCodec.restoreValue(BackupCodec.canonicalizeValue(value)) as Map,
    );

class VaultPassword {
  final String id;
  final String label;
  final String ciphertext;

  const VaultPassword(this.id, this.label, this.ciphertext);
}

class VaultSource {
  final String path;
  final Map<String, dynamic> data;

  VaultSource(this.path, Map<String, dynamic> data) : data = _copy(data);

  List<VaultPassword> get passwords {
    if (path.split('/')[2] == 'credentials') {
      return [_password(path.split('/').last, data)];
    }
    final records = data['records'];
    if (records is! List) throw _invalid();
    final result = <VaultPassword>[];
    final seen = <String>{};
    for (final record in records) {
      if (record is! Map ||
          record['id'] is! String ||
          record['data'] is! Map ||
          !seen.add(record['id'] as String)) {
        throw _invalid();
      }
      result.add(
        _password(
          record['id'] as String,
          Map<String, dynamic>.from(record['data'] as Map),
        ),
      );
    }
    if (result.isEmpty) throw _invalid();
    return result;
  }

  VaultPassword _password(String id, Map<String, dynamic> value) {
    final encrypted = value['encrypted_password'];
    if (id.isEmpty || encrypted is! String) throw _invalid();
    return VaultPassword(
      id,
      value['location']?.toString() ?? 'Credencial',
      encrypted,
    );
  }

  VaultException _invalid() => const VaultException(
    VaultErrorCode.malformedEnvelope,
    'Há uma credencial incompleta no cofre ou na lixeira. Revise os dados antes de continuar.',
  );

  Map<String, dynamic> replacePasswords(Map<String, String> values) {
    final result = _copy(data);
    if (path.split('/')[2] == 'credentials') {
      result['encrypted_password'] = values[passwords.single.id]!;
    } else {
      for (final record in result['records'] as List) {
        (record['data'] as Map)['encrypted_password'] = values[record['id']]!;
      }
    }
    return result;
  }
}

class VaultInventory {
  final List<VaultSource> sources;

  VaultInventory(List<VaultSource> sources)
    : sources = List.unmodifiable(
        sources..sort((a, b) => a.path.compareTo(b.path)),
      );

  int get passwordCount =>
      sources.fold(0, (total, source) => total + source.passwords.length);
  bool get hasLegacy => sources.any(
    (source) =>
        source.passwords.any((p) => !isVersionedVaultValue(p.ciphertext)),
  );
  String get digest =>
      vaultDigest({for (final source in sources) source.path: source.data});

  static Future<VaultInventory> capture(VaultStore store, String uid) async {
    final data = await Future.wait([
      store.list('users/$uid/credentials'),
      store.list('users/$uid/trash'),
    ]);
    final sources = [
      for (final entry in data[0].entries)
        VaultSource('users/$uid/credentials/${entry.key}', entry.value),
      for (final entry in data[1].entries)
        if (entry.value['collection'] == 'credentials')
          VaultSource('users/$uid/trash/${entry.key}', entry.value),
    ];
    final inventory = VaultInventory(sources);
    inventory.passwordCount;
    return inventory;
  }
}

class VaultPreviewEntry {
  final String sourcePath;
  final String credentialId;
  final String label;
  final String plaintext;
  final bool inTrash;

  const VaultPreviewEntry(
    this.sourcePath,
    this.credentialId,
    this.label,
    this.plaintext,
    this.inTrash,
  );
}

class VaultMigrationPreview {
  final String uid;
  final VaultInventory inventory;
  final List<VaultPreviewEntry> entries;
  final List<String> failures;

  VaultMigrationPreview(
    this.uid,
    this.inventory,
    List<VaultPreviewEntry> entries,
    List<String> failures,
  ) : entries = List.unmodifiable(entries),
      failures = List.unmodifiable(failures);

  bool get canProceed =>
      entries.isNotEmpty &&
      failures.isEmpty &&
      entries.length == inventory.passwordCount;
}

(List<VaultPreviewEntry>, List<String>) _readLegacyPreview(
  ({String input, String uid, List<VaultSource> sources, VaultCipher? cipher})
  request,
) {
  final reader = LegacyVaultReader(request.input);
  final entries = <VaultPreviewEntry>[];
  final failures = <String>[];
  for (final source in request.sources) {
    for (final password in source.passwords) {
      try {
        final plain = isVersionedVaultValue(password.ciphertext)
            ? request.cipher?.decrypt(
                password.ciphertext,
                uid: request.uid,
                recordId: password.id,
              )
            : reader.decrypt(password.ciphertext);
        if (plain == null ||
            utf8.encode(plain).length > VaultCipher.maxPasswordBytes) {
          throw const FormatException();
        }
        entries.add(
          VaultPreviewEntry(
            source.path,
            password.id,
            password.label,
            plain,
            source.path.contains('/trash/'),
          ),
        );
      } catch (_) {
        failures.add(password.label);
      }
    }
  }
  return (entries, failures);
}

class VaultMigrationService {
  static const chunkSize = 128 * 1024;
  static const maxBackupBytes = 200 * 1024 * 1024;
  final VaultStore store;
  final String uid;
  final bool Function()? isSessionActive;
  final Future<void> Function()? beforeMutation;
  VaultMigrationPreview? _preview;
  bool _running = false;

  VaultMigrationService({
    required this.store,
    required this.uid,
    this.isSessionActive,
    this.beforeMutation,
  });

  String get _configPath => 'users/$uid/vault/config';
  String _jobPath(String id) => 'users/$uid/vault_migrations/$id';
  String _itemPath(String id, String source) =>
      '${_jobPath(id)}/items/${sha256.convert(utf8.encode(source))}';

  void _check() {
    if (isSessionActive != null && !isSessionActive!()) {
      throw const VaultException(
        VaultErrorCode.unavailable,
        'A sessão mudou. Abra o cofre novamente.',
      );
    }
  }

  Future<VaultMigrationPreview> preview(
    String input, {
    VaultCipher? currentCipher,
  }) async {
    _check();
    final normalized = normalizeLegacyKey(input);
    final inventory = await VaultInventory.capture(store, uid);
    _check();
    final (entries, failures) = await compute(_readLegacyPreview, (
      input: normalized,
      uid: uid,
      sources: inventory.sources,
      cipher: currentCipher,
    ));
    _check();
    _preview = VaultMigrationPreview(uid, inventory, entries, failures);
    return _preview!;
  }

  void discardPreview() => _preview = null;

  Future<void> start(
    VaultMigrationPreview preview, {
    required bool confirmed,
    void Function(String, int, int)? onProgress,
  }) async {
    if (!confirmed ||
        !identical(preview, _preview) ||
        !preview.canProceed ||
        preview.uid != uid) {
      throw const VaultException(
        VaultErrorCode.confirmationRequired,
        'Confira todas as senhas e confirme a atualização.',
      );
    }
    await _exclusive(() async {
      final inventory = await VaultInventory.capture(store, uid);
      _check();
      if (inventory.digest != preview.inventory.digest) throw _conflict();
      final previous = await store.read(_configPath);
      final migrationId =
          previous?['migrationId'] as String? ??
          store.newId('users/$uid/vault_migrations');
      final key = await VaultKeyRepository(
        store,
      ).ensure(uid, migrationId: migrationId);
      try {
        _check();
        final now = Timestamp.now();
        await store.transaction((tx) async {
          final config = await tx.read(_configPath);
          final job = await tx.read(_jobPath(migrationId));
          _check();
          if (config == null ||
              config['state'] == 'ready' ||
              config['activeKeyId'] != key.id ||
              config['migrationId'] != migrationId ||
              job?['backupVerifiedAt'] != null) {
            throw _conflict();
          }
          tx.set(_configPath, {
            ...config,
            'state': 'preparing',
            'updatedAt': now,
          });
          tx.set(_jobPath(migrationId), {
            'schemaVersion': 1,
            'keyId': key.id,
            'phase': 'preparingBackup',
            'inventoryDigest': inventory.digest,
            'sourceDocumentCount': inventory.sources.length,
            'sourcePasswordCount': inventory.passwordCount,
            'createdAt': now,
            'updatedAt': now,
          });
        });
        onProgress?.call(
          'Criando e verificando o backup',
          0,
          inventory.sources.length,
        );
        final portableBySource = <String, Map<String, String>>{};
        for (final entry in preview.entries) {
          (portableBySource[entry.sourcePath] ??= {})[entry.credentialId] =
              entry.plaintext;
        }
        final payload = {
          'schemaVersion': 1,
          'uid': uid,
          'migrationId': migrationId,
          'keyId': key.id,
          'sources': [
            for (final source in inventory.sources)
              {
                'path': source.path,
                'data': source.data,
                'passwords': portableBySource[source.path]!,
              },
          ],
        };
        await _saveBackup(migrationId, key, payload);
        final backedUp = await _loadBackup(migrationId, key);
        if (vaultDigest(backedUp) != vaultDigest(payload)) {
          throw _invalidBackup();
        }
        for (final source in inventory.sources) {
          _check();
          await store.set(_itemPath(migrationId, source.path), {
            'sourcePath': source.path,
            'beforeDigest': vaultDigest(source.data),
            'status': 'pending',
          });
        }
        await _phase(
          migrationId,
          'backupVerified',
          extra: {'backupVerifiedAt': Timestamp.now()},
        );
        _preview = null;
        await _apply(migrationId, key, backedUp, onProgress);
      } finally {
        key.dispose();
      }
    });
  }

  Future<void> resume(
    String migrationId, {
    void Function(String, int, int)? onProgress,
  }) => _exclusive(() async {
    final job = await store.read(_jobPath(migrationId));
    _check();
    if (job == null ||
        job['backupVerifiedAt'] == null ||
        job['keyId'] is! String) {
      throw _invalidBackup();
    }
    final key = await VaultKeyRepository(
      store,
    ).load(uid, job['keyId'] as String);
    try {
      final backup = await _loadBackup(migrationId, key);
      await _apply(migrationId, key, backup, onProgress);
    } finally {
      key.dispose();
    }
  });

  Future<void> _exclusive(Future<void> Function() action) async {
    if (_running) {
      throw const VaultException(
        VaultErrorCode.unavailable,
        'Já existe uma operação em andamento.',
      );
    }
    _check();
    _running = true;
    try {
      await beforeMutation?.call();
      _check();
      await action();
    } finally {
      _running = false;
    }
  }

  List<int> _backupAad(String id, String keyId) =>
      utf8.encode(jsonEncode(['keybudget-vault-migration', 1, uid, id, keyId]));

  Future<void> _saveBackup(
    String id,
    VaultKey key,
    Map<String, dynamic> payload,
  ) async {
    final aad = _backupAad(id, key.id);
    final bytes = key.bytes.toList();
    final keyId = key.id;
    final sealed = await compute((_) {
      final json = utf8.encode(
        jsonEncode(BackupCodec.canonicalizeValue(payload)),
      );
      final zip = BackupCrypto.packArchive({'vault.json': json});
      final cipher = VaultCipher(keyId: keyId, key: bytes);
      try {
        return cipher.seal(zip, aad);
      } finally {
        cipher.dispose();
      }
    }, null);
    if (sealed.length > maxBackupBytes) throw _invalidBackup();
    final count = (sealed.length / chunkSize).ceil();
    final generation = store.newId('${_jobPath(id)}/backup_chunks');
    for (var i = 0; i < count; i++) {
      _check();
      final end = ((i + 1) * chunkSize).clamp(0, sealed.length);
      await store.set(
        '${_jobPath(id)}/backup_chunks/$generation-${i.toString().padLeft(6, '0')}',
        {
          'index': i,
          'bytes': Blob(Uint8List.fromList(sealed.sublist(i * chunkSize, end))),
        },
      );
    }
    await _phase(
      id,
      'preparingBackup',
      extra: {
        'backupChunkCount': count,
        'backupGeneration': generation,
        'backupDigest': sha256.convert(sealed).toString(),
      },
    );
  }

  Future<Map<String, dynamic>> _loadBackup(String id, VaultKey key) async {
    final job = await store.read(_jobPath(id));
    final allChunks = await store.list('${_jobPath(id)}/backup_chunks');
    final generation = job?['backupGeneration'];
    if (generation is! String || generation.isEmpty) throw _invalidBackup();
    final chunks = {
      for (final entry in allChunks.entries)
        if (entry.key.startsWith('$generation-'))
          entry.key.substring(generation.length + 1): entry.value,
    };
    _check();
    final count = job?['backupChunkCount'];
    if (count is! int ||
        count <= 0 ||
        count > (maxBackupBytes / chunkSize).ceil() ||
        chunks.length != count) {
      throw _invalidBackup();
    }
    final builder = BytesBuilder(copy: false);
    for (var i = 0; i < count; i++) {
      final chunk = chunks[i.toString().padLeft(6, '0')];
      if (chunk?['index'] != i || chunk?['bytes'] is! Blob) {
        throw _invalidBackup();
      }
      final bytes = (chunk!['bytes'] as Blob).bytes;
      if (bytes.isEmpty || bytes.length > chunkSize) throw _invalidBackup();
      builder.add(bytes);
    }
    final sealed = builder.takeBytes();
    if (sealed.length > maxBackupBytes ||
        sha256.convert(sealed).toString() != job?['backupDigest']) {
      throw _invalidBackup();
    }
    final aad = _backupAad(id, key.id);
    final bytes = key.bytes.toList();
    final keyId = key.id;
    final payload = await compute((_) {
      final cipher = VaultCipher(keyId: keyId, key: bytes);
      try {
        final archive = BackupCrypto.unpackArchive(cipher.open(sealed, aad));
        if (archive.length != 1 || archive['vault.json'] == null) {
          throw const FormatException();
        }
        return Map<String, dynamic>.from(
          BackupCodec.restoreValue(
                jsonDecode(utf8.decode(archive['vault.json']!)),
              )
              as Map,
        );
      } finally {
        cipher.dispose();
      }
    }, null);
    if (payload['schemaVersion'] != 1 ||
        payload['uid'] != uid ||
        payload['migrationId'] != id ||
        payload['keyId'] != key.id ||
        payload['sources'] is! List) {
      throw _invalidBackup();
    }
    return payload;
  }

  List<(VaultSource, Map<String, String>)> _sources(
    Map<String, dynamic> payload,
  ) {
    final result = <(VaultSource, Map<String, String>)>[];
    final seen = <String>{};
    for (final raw in payload['sources'] as List) {
      final path = raw['path'] as String;
      final parts = path.split('/');
      if (parts.length != 4 ||
          parts[0] != 'users' ||
          parts[1] != uid ||
          !{'credentials', 'trash'}.contains(parts[2]) ||
          parts[3].isEmpty ||
          !seen.add(path)) {
        throw _invalidBackup();
      }
      final source = VaultSource(
        path,
        Map<String, dynamic>.from(raw['data'] as Map),
      );
      if (parts[2] == 'trash' && source.data['collection'] != 'credentials') {
        throw _invalidBackup();
      }
      final passwords = Map<String, String>.from(raw['passwords'] as Map);
      if (source.passwords.length != passwords.length ||
          source.passwords.any((p) => !passwords.containsKey(p.id))) {
        throw _invalidBackup();
      }
      result.add((source, passwords));
    }
    return result;
  }

  Future<void> _apply(
    String id,
    VaultKey key,
    Map<String, dynamic> backup,
    void Function(String, int, int)? progress,
  ) async {
    final sources = _sources(backup);
    final cipher = key.cipher();
    try {
      await _phase(id, 'migrating');
      for (var i = 0; i < sources.length; i++) {
        _check();
        final (source, passwords) = sources[i];
        final updated = source.replacePasswords({
          for (final entry in passwords.entries)
            entry.key: cipher.encrypt(
              entry.value,
              uid: uid,
              recordId: entry.key,
            ),
        });
        final afterDigest = vaultDigest(updated);
        await store.transaction((tx) async {
          final item = await tx.read(_itemPath(id, source.path));
          final current = await tx.read(source.path);
          final job = await tx.read(_jobPath(id));
          _check();
          if (job?['backupVerifiedAt'] == null ||
              job?['keyId'] != key.id ||
              item == null ||
              current == null) {
            throw _conflict();
          }
          if ({'committed', 'verified'}.contains(item['status'])) {
            if (vaultDigest(current) != item['afterDigest']) throw _conflict();
            return;
          }
          if (vaultDigest(current) != item['beforeDigest'] ||
              item['beforeDigest'] != vaultDigest(source.data)) {
            throw _conflict();
          }
          tx.set(source.path, updated);
          tx.set(_itemPath(id, source.path), {
            ...item,
            'status': 'committed',
            'afterDigest': afterDigest,
          });
        });
        progress?.call('Atualizando a proteção', i + 1, sources.length);
      }
      await _phase(id, 'verifying');
      final inventory = await VaultInventory.capture(store, uid);
      _check();
      if (inventory.sources.length != sources.length) throw _conflict();
      for (final (source, passwords) in sources) {
        final current = await store.read(source.path);
        final item = await store.read(_itemPath(id, source.path));
        _check();
        if (current == null || vaultDigest(current) != item?['afterDigest']) {
          throw _conflict();
        }
        for (final password in VaultSource(source.path, current).passwords) {
          if (cipher.decrypt(
                password.ciphertext,
                uid: uid,
                recordId: password.id,
              ) !=
              passwords[password.id]) {
            throw _conflict();
          }
        }
      }
      if (inventory.hasLegacy) throw _conflict();
      await _phase(id, 'completed');
      progress?.call('Proteção verificada', sources.length, sources.length);
    } finally {
      cipher.dispose();
    }
  }

  Future<void> rollback(
    String id, {
    void Function(String, int, int)? onProgress,
  }) => _exclusive(() async {
    final job = await store.read(_jobPath(id));
    _check();
    if (job?['backupVerifiedAt'] == null || job?['keyId'] is! String) {
      throw _invalidBackup();
    }
    final key = await VaultKeyRepository(
      store,
    ).load(uid, job!['keyId'] as String);
    try {
      final sources = _sources(await _loadBackup(id, key));
      await _phase(id, 'rollingBack');
      for (var i = 0; i < sources.length; i++) {
        _check();
        final source = sources[i].$1;
        await store.transaction((tx) async {
          final item = await tx.read(_itemPath(id, source.path));
          final current = await tx.read(source.path);
          _check();
          if (item == null || current == null) throw _conflict();
          if (item['status'] == 'pending' || item['status'] == 'rolledBack') {
            if (vaultDigest(current) != item['beforeDigest']) throw _conflict();
            return;
          }
          if (vaultDigest(current) != item['afterDigest']) throw _conflict();
          tx.set(source.path, source.data);
          tx.set(_itemPath(id, source.path), {...item, 'status': 'rolledBack'});
        });
        onProgress?.call(
          'Restaurando os dados originais',
          i + 1,
          sources.length,
        );
      }
      await _phase(id, 'rolledBack');
    } finally {
      key.dispose();
    }
  });

  Future<void> _phase(
    String id,
    String phase, {
    Map<String, dynamic> extra = const {},
  }) async {
    _check();
    await store.transaction((tx) async {
      final job = await tx.read(_jobPath(id));
      final config = await tx.read(_configPath);
      _check();
      if (job == null ||
          config == null ||
          config['migrationId'] != id ||
          config['activeKeyId'] != job['keyId']) {
        throw _conflict();
      }
      final now = Timestamp.now();
      tx.set(_jobPath(id), {
        ...job,
        ...extra,
        'phase': phase,
        'updatedAt': now,
      });
      tx.set(_configPath, {
        ...config,
        'state': phase == 'completed'
            ? 'ready'
            : phase == 'rolledBack'
            ? 'rolledBack'
            : phase,
        if (phase == 'completed') 'legacyMigrationCompletedAt': now,
        'updatedAt': now,
      });
    });
  }

  VaultException _conflict() => const VaultException(
    VaultErrorCode.conflict,
    'Os dados mudaram ou estão incompletos. Nada será sobrescrito sem conferência. Retome a operação.',
  );
  VaultException _invalidBackup() => const VaultException(
    VaultErrorCode.invalidBackup,
    'O backup da migração ainda não está completo ou não pôde ser verificado.',
  );
}
