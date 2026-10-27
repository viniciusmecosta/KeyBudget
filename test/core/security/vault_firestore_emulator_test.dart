import '../../helpers/firebase_emulator_plugins_stub.dart'
    if (dart.library.js_interop) '../../helpers/firebase_emulator_plugins_web.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypt/encrypt.dart' as legacy;
import 'package:key_budget/core/security/vault_key_repository.dart';
import 'package:key_budget/core/security/vault_store.dart';
import 'package:key_budget/features/credentials/application/vault_migration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('VAULT_EMULATOR_TESTS')) registerFirebaseEmulatorPlugins();
  test(
    'Firestore persists authenticated migration checkpoints and recovery',
    () async {
      final app = await Firebase.initializeApp(
        name: 'vault-emulator',
        options: const FirebaseOptions(
          apiKey: 'demo-api-key',
          appId: '1:123456789:web:abcdef',
          messagingSenderId: '123456789',
          projectId: 'demo-keybudget',
        ),
      );
      final auth = FirebaseAuth.instanceFor(app: app);
      await auth.useAuthEmulator('127.0.0.1', 9099);
      final firestore = FirebaseFirestore.instanceFor(app: app);
      firestore.settings = const Settings(persistenceEnabled: false);
      firestore.useFirestoreEmulator('127.0.0.1', 8080);
      final credential = await auth.createUserWithEmailAndPassword(
        email: 'vault-${DateTime.now().microsecondsSinceEpoch}@example.test',
        password: 'synthetic-test-password',
      );
      final uid = credential.user!.uid;
      final store = FirestoreVaultStore(firestore: firestore);
      const key = '12345678901234567890123456789012';
      final iv = legacy.IV.allZerosOfLength(16);
      final oldCipher = legacy.Encrypter(legacy.AES(legacy.Key.fromUtf8(key)));
      final original =
          '${iv.base64}:${oldCipher.encrypt('password-🔑', iv: iv).base64}';
      final path = 'users/$uid/credentials/one';
      await store.set(path, {'encrypted_password': original});
      final service = VaultMigrationService(store: store, uid: uid);
      final preview = await service.preview(key);
      expect(preview.canProceed, isTrue);
      expect(await store.read('users/$uid/vault/config'), isNull);
      await service.start(preview, confirmed: true);
      final config = (await store.read('users/$uid/vault/config'))!;
      expect(config['state'], 'ready');
      final id = config['migrationId'] as String;
      final persisted = await VaultKeyRepository(
        store,
      ).load(uid, config['activeKeyId'] as String);
      final cipher = persisted.cipher();
      expect(
        cipher.decrypt(
          (await store.read(path))!['encrypted_password'] as String,
          uid: uid,
          recordId: 'one',
        ),
        'password-🔑',
      );
      await VaultMigrationService(store: store, uid: uid).rollback(id);
      expect((await store.read(path))!['encrypted_password'], original);
      await VaultMigrationService(store: store, uid: uid).resume(id);
      expect((await store.read('users/$uid/vault/config'))!['state'], 'ready');
      cipher.dispose();
      persisted.dispose();
      await auth.signOut();
      await app.delete();
    },
    skip: !const bool.fromEnvironment('VAULT_EMULATOR_TESTS'),
  );
}
