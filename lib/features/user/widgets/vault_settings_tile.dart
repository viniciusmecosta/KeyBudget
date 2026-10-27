import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/app/utils/navigation_utils.dart';
import 'package:passfin/core/security/vault_session.dart';
import 'package:passfin/features/credentials/view/vault_migration_screen.dart';
import 'settings_tile.dart';

class VaultSettingsTile extends ConsumerWidget {
  const VaultSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultSessionProvider);
    if (vault.canImportLegacy || vault.needsRecovery) {
      return SettingsTile(
        icon: Icons.key_outlined,
        title: vault.canImportLegacy
            ? 'Incluir chave legada'
            : 'Retomar migração',
        subtitle: vault.canImportLegacy
            ? 'Confira as senhas e atualize a proteção do cofre'
            : 'Continue ou desfaça a atualização salva',
        onTap: () =>
            NavigationUtils.push(context, const VaultMigrationScreen()),
      );
    }
    if (vault.status == VaultStatus.ready) {
      return SettingsTile(
        icon: Icons.verified_user_outlined,
        title: 'Proteção do cofre',
        subtitle: vault.hasVerifiedBackup
            ? 'Chave individual e backup da migração verificados'
            : 'Chave individual salva na sua conta',
        onTap: () =>
            NavigationUtils.push(context, const VaultMigrationScreen()),
      );
    }
    if (vault.status == VaultStatus.unavailable) {
      return SettingsTile(
        icon: Icons.sync_problem_outlined,
        title: 'Recuperar acesso ao cofre',
        subtitle: vault.error,
        onTap: () => vault.open(vault.userId),
      );
    }
    if (vault.status == VaultStatus.loading) {
      return const ListTile(
        leading: Icon(Icons.shield_outlined),
        title: Text('Abrindo a proteção do cofre'),
        trailing: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
