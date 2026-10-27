import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/security/vault_store.dart';

dynamic _copyValue(dynamic value) {
  if (value is Map) {
    return {
      for (final entry in value.entries) entry.key: _copyValue(entry.value),
    };
  }
  if (value is List) return value.map(_copyValue).toList();
  if (value is Blob) return Blob(value.bytes);
  return value;
}

Map<String, dynamic> copyVaultMap(Map<String, dynamic> data) =>
    Map<String, dynamic>.from(_copyValue(data) as Map);

class MemoryVaultStore implements VaultStore {
  final Map<String, Map<String, dynamic>> documents = {};
  int writes = 0;
  int nextId = 0;
  int? failSourceWriteAt;
  int sourceWrites = 0;
  String? failReadPath;
  int? failWriteAt;

  @override
  String newId(String collection) => 'id-${nextId++}';

  @override
  Future<Map<String, dynamic>?> read(String path) async {
    if (path == failReadPath) throw StateError('injected read failure');
    final data = documents[path];
    return data == null ? null : copyVaultMap(data);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> list(String collection) async => {
    for (final entry in documents.entries)
      if (entry.key.startsWith('$collection/') &&
          !entry.key.substring(collection.length + 1).contains('/'))
        entry.key.substring(collection.length + 1): copyVaultMap(entry.value),
  };

  @override
  Future<void> set(String path, Map<String, dynamic> data) async {
    if (failWriteAt == writes) throw StateError('injected write failure');
    documents[path] = copyVaultMap(data);
    writes++;
  }

  @override
  Future<void> transaction(
    Future<void> Function(VaultTransaction tx) action,
  ) async {
    final tx = _MemoryTransaction(this);
    await action(tx);
    if (failWriteAt != null &&
        failWriteAt! >= writes &&
        failWriteAt! < writes + tx.pending.length) {
      throw StateError('injected transaction failure');
    }
    for (final path in tx.pending.keys) {
      if (path.contains('/credentials/') || path.contains('/trash/')) {
        if (failSourceWriteAt == sourceWrites) {
          throw StateError('injected source failure');
        }
        sourceWrites++;
      }
    }
    for (final entry in tx.pending.entries) {
      await set(entry.key, entry.value);
    }
  }
}

class _MemoryTransaction implements VaultTransaction {
  final MemoryVaultStore store;
  final Map<String, Map<String, dynamic>> pending = {};

  _MemoryTransaction(this.store);

  @override
  Future<Map<String, dynamic>?> read(String path) => store.read(path);

  @override
  void set(String path, Map<String, dynamic> data) =>
      pending[path] = copyVaultMap(data);
}
