import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vault_crypto.dart';
import 'vault_store.dart';

class VaultKey {
  final String id;
  final Uint8List bytes;

  VaultKey(this.id, List<int> bytes) : bytes = Uint8List.fromList(bytes);

  factory VaultKey.fromMap(String id, Map<String, dynamic> map) {
    try {
      if (map['schemaVersion'] != 1 ||
          map['algorithm'] != 'A256GCM' ||
          map['keyEncoding'] != 'base64') {
        throw const FormatException();
      }
      final bytes = base64.decode(map['keyMaterial'] as String);
      if (id.isEmpty || bytes.length != 32) throw const FormatException();
      return VaultKey(id, bytes);
    } catch (_) {
      throw const VaultException(
        VaultErrorCode.unknownKey,
        'A chave persistida do cofre é inválida.',
      );
    }
  }

  Map<String, dynamic> toMap() => {
    'schemaVersion': 1,
    'algorithm': 'A256GCM',
    'keyEncoding': 'base64',
    'keyMaterial': base64.encode(bytes),
  };

  VaultCipher cipher() => VaultCipher(keyId: id, key: bytes);

  void dispose() => bytes.fillRange(0, bytes.length, 0);
}

class VaultKeyRepository {
  final VaultStore store;

  VaultKeyRepository(this.store);

  String configPath(String uid) => 'users/$uid/vault/config';
  String keyPath(String uid, String id) => 'users/$uid/vault_keys/$id';

  Future<VaultKey> load(String uid, String id) async {
    final data = await store.read(keyPath(uid, id));
    if (data == null) {
      throw const VaultException(
        VaultErrorCode.unknownKey,
        'A chave deste cofre não foi encontrada. Tente novamente.',
      );
    }
    return VaultKey.fromMap(id, data);
  }

  Future<VaultKey> ensure(String uid, {String? migrationId}) async {
    final candidate = VaultKey(
      store.newId('users/$uid/vault_keys'),
      vaultRandomBytes(32),
    );
    try {
      await store.transaction((tx) async {
        final config = await tx.read(configPath(uid));
        final existing = await tx.read(keyPath(uid, candidate.id));
        if (config != null) {
          if (config['schemaVersion'] != 1 ||
              config['activeKeyId'] is! String) {
            throw const VaultException(
              VaultErrorCode.unknownKey,
              'A configuração do cofre precisa ser recuperada.',
            );
          }
          return;
        }
        if (existing != null) {
          throw const VaultException(
            VaultErrorCode.conflict,
            'Não foi possível reservar a chave. Tente novamente.',
          );
        }
        final now = Timestamp.now();
        tx.set(keyPath(uid, candidate.id), {
          ...candidate.toMap(),
          'createdAt': now,
        });
        tx.set(configPath(uid), {
          'schemaVersion': 1,
          'writeFormatVersion': 2,
          'activeKeyId': candidate.id,
          'state': migrationId == null ? 'ready' : 'preparing',
          if (migrationId != null) 'migrationId': migrationId,
          'createdAt': now,
          'updatedAt': now,
        });
      });
      final config = await store.read(configPath(uid));
      if (config == null || config['activeKeyId'] is! String) {
        throw const VaultException(
          VaultErrorCode.unavailable,
          'Não foi possível confirmar a chave do cofre.',
        );
      }
      final key = await load(uid, config['activeKeyId'] as String);
      final cipher = key.cipher();
      try {
        final probe = base64.encode(vaultRandomBytes(24));
        final encrypted = cipher.encrypt(
          probe,
          uid: uid,
          recordId: 'key-verification',
        );
        if (cipher.decrypt(encrypted, uid: uid, recordId: 'key-verification') !=
            probe) {
          throw const VaultException(
            VaultErrorCode.authenticationFailed,
            'Não foi possível verificar a chave.',
          );
        }
      } finally {
        cipher.dispose();
      }
      return key;
    } finally {
      candidate.dispose();
    }
  }
}
