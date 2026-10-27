import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/security/vault_session.dart';
import 'package:key_budget/features/user/widgets/vault_settings_tile.dart';
import '../../core/security/memory_vault_store.dart';

void main() {
  testWidgets(
    'profile migration requires review and clears temporary input on cancel',
    (tester) async {
      const key = '12345678901234567890123456789012';
      final iv = legacy.IV.allZerosOfLength(16);
      final encrypted = legacy.Encrypter(
        legacy.AES(legacy.Key.fromUtf8(key)),
      ).encrypt('synthetic-password', iv: iv);
      final store = MemoryVaultStore();
      store.documents['users/owner/credentials/one'] = {
        'location': 'Portal',
        'encrypted_password': '${iv.base64}:${encrypted.base64}',
      };
      final session = VaultSession(store: store);
      await session.open('owner');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [vaultSessionProvider.overrideWith((ref) => session)],
          child: const MaterialApp(home: Scaffold(body: VaultSettingsTile())),
        ),
      );
      await tester.tap(find.text('Incluir chave legada'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '  $key\n');
      await tester.ensureVisible(find.text('Testar chave'));
      await tester.tap(find.text('Testar chave'));
      await tester.pumpAndSettle();
      expect(find.text('synthetic-password'), findsNothing);
      expect(store.writes, 0);
      final apply = find.widgetWithText(AppButton, 'Criar backup e migrar');
      expect(tester.widget<AppButton>(apply).onPressed, isNull);
      await tester.ensureVisible(find.byTooltip('Conferir senha'));
      await tester.tap(find.byTooltip('Conferir senha'));
      await tester.pumpAndSettle();
      expect(find.text('synthetic-password'), findsOneWidget);
      await tester.ensureVisible(find.text('Cancelar conferência'));
      await tester.tap(find.text('Cancelar conferência'));
      await tester.pumpAndSettle();
      expect(store.writes, 0);
      expect(find.text('synthetic-password'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        isEmpty,
      );
    },
  );
}
