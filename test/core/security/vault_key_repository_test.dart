import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/security/vault_crypto.dart';
import 'package:key_budget/core/security/vault_key_repository.dart';
import 'memory_vault_store.dart';

void main() {
  test('disposed key material cannot create another cipher', () {
    final key = VaultKey('key', List.filled(32, 8));
    key.dispose();
    expect(key.bytes, everyElement(0));
    expect(() => key.cipher(), throwsA(isA<VaultException>()));
  });

  test(
    'initialization preserves the persisted key and separates owners',
    () async {
      final store = MemoryVaultStore();
      final repository = VaultKeyRepository(store);
      final first = await repository.ensure('a');
      final second = await repository.ensure('a');
      final other = await repository.ensure('b');
      expect(first.id, second.id);
      expect(first.bytes, second.bytes);
      expect(first.bytes, isNot(other.bytes));
      expect(first.bytes.length, 32);
    },
  );

  test('missing referenced keys are not silently replaced', () async {
    final store = MemoryVaultStore();
    final repository = VaultKeyRepository(store);
    await repository.ensure('a');
    store.documents.removeWhere((path, _) => path.contains('/vault_keys/'));
    final writes = store.writes;
    await expectLater(repository.ensure('a'), throwsA(isA<VaultException>()));
    expect(store.writes, writes);
  });
}
