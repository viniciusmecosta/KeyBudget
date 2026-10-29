import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/security/vault_session.dart';
import 'package:passfin/core/security/vault_key_repository.dart';
import 'package:passfin/features/user/widgets/vault_settings_tile.dart';
import '../../core/security/memory_vault_store.dart';

void main() {
  testWidgets('profile hides legacy entry once a versioned key exists', (
    tester,
  ) async {
    final store = MemoryVaultStore();
    store.documents['users/owner/credentials/one'] = {
      'encrypted_password': 'iv:legacy',
    };
    final session = VaultSession(store: store);
    await session.open('owner');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [vaultSessionProvider.overrideWith((ref) => session)],
        child: const MaterialApp(home: Scaffold(body: VaultSettingsTile())),
      ),
    );
    expect(find.text('Incluir chave legada'), findsOneWidget);
    await VaultKeyRepository(store).ensure('owner', migrationId: 'op');
    await session.open('owner');
    await tester.pumpAndSettle();
    expect(find.text('Incluir chave legada'), findsNothing);
    expect(find.text('Retomar migração'), findsOneWidget);
  });

  testWidgets('new account never shows legacy entry', (tester) async {
    final session = VaultSession(store: MemoryVaultStore());
    await session.open('new');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [vaultSessionProvider.overrideWith((ref) => session)],
        child: const MaterialApp(home: Scaffold(body: VaultSettingsTile())),
      ),
    );
    expect(find.text('Incluir chave legada'), findsNothing);
    expect(find.text('Retomar migração'), findsNothing);
    expect(find.text('Proteção do cofre'), findsNothing);
  });
}
