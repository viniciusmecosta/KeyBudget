import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/categories_screen.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/user/view/edit_user_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../widgets/settings_tile.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  Future<void> _performBackup(
      BuildContext context, bool exp, bool rec, bool cred, bool cat) async {
    try {
      final driveService = DriveService();
      final csvService = CsvService();
      final dir = await getTemporaryDirectory();

      final expVm = Provider.of<ExpenseViewModel>(context, listen: false);
      final credVm = Provider.of<CredentialViewModel>(context, listen: false);
      final catVm = Provider.of<CategoryViewModel>(context, listen: false);

      int successCount = 0;

      if (exp) {
        final csvStr = csvService.generateExpensesCsvString(expVm.allExpenses);
        final file = File('${dir.path}/despesas_backup.csv');
        await file.writeAsBytes(utf8.encode(csvStr));
        final res =
            await driveService.uploadFile(file, (p0, p1) {}, isBackup: true);
        if (res != null) successCount++;
      }

      if (rec) {
        final csvStr = csvService
            .generateRecurringExpensesCsvString(expVm.recurringExpenses);
        final file = File('${dir.path}/despesas_recorrentes_backup.csv');
        await file.writeAsBytes(utf8.encode(csvStr));
        final res =
            await driveService.uploadFile(file, (p0, p1) {}, isBackup: true);
        if (res != null) successCount++;
      }

      if (cred) {
        final csvStr = csvService.generateCredentialsCsvString(
            credVm.allCredentials, credVm.decryptPassword);
        final file = File('${dir.path}/credenciais_backup.csv');
        await file.writeAsBytes(utf8.encode(csvStr));
        final res =
            await driveService.uploadFile(file, (p0, p1) {}, isBackup: true);
        if (res != null) successCount++;
      }

      if (cat) {
        final csvStr = csvService.generateCategoriesCsvString(catVm.categories);
        final file = File('${dir.path}/categorias_backup.csv');
        await file.writeAsBytes(utf8.encode(csvStr));
        final res =
            await driveService.uploadFile(file, (p0, p1) {}, isBackup: true);
        if (res != null) successCount++;
      }

      if (context.mounted) {
        if (successCount > 0) {
          SnackbarService.showSuccess(context,
              'Backup de $successCount arquivo(s) concluído na pasta Backup do Drive!');
        } else {
          SnackbarService.showError(
              context, 'Nenhum arquivo foi salvo. Verifique sua conexão.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarService.showError(context, 'Erro ao realizar backup: $e');
      }
    }
  }

  void _showBackupDialog(BuildContext context) {
    bool backupExpenses = true;
    bool backupRecurring = true;
    bool backupCredentials = true;
    bool backupCategories = true;
    bool isBackingUp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Backup no Google Drive',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecione os dados que deseja exportar em formato CSV diretamente para o seu Drive.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  title: const Text('Despesas',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  value: backupExpenses,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: isBackingUp
                      ? null
                      : (v) => setState(() => backupExpenses = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Despesas Recorrentes',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  value: backupRecurring,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: isBackingUp
                      ? null
                      : (v) => setState(() => backupRecurring = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Credenciais',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  value: backupCredentials,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: isBackingUp
                      ? null
                      : (v) => setState(() => backupCredentials = v ?? true),
                ),
                CheckboxListTile(
                  title: const Text('Categorias',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  value: backupCategories,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: isBackingUp
                      ? null
                      : (v) => setState(() => backupCategories = v ?? true),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isBackingUp ||
                            (!backupExpenses &&
                                !backupRecurring &&
                                !backupCredentials &&
                                !backupCategories)
                        ? null
                        : () async {
                            setState(() => isBackingUp = true);
                            await _performBackup(
                              context,
                              backupExpenses,
                              backupRecurring,
                              backupCredentials,
                              backupCategories,
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                    child: isBackingUp
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Iniciar Backup'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meu Perfil',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              NavigationUtils.push(context, const EditUserScreen());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<AuthViewModel>(
          builder: (context, authViewModel, child) {
            final user = authViewModel.currentUser;
            final avatarPath = user?.avatarPath;
            ImageProvider? imageProvider;

            if (avatarPath != null && avatarPath.isNotEmpty) {
              if (Uri.tryParse(avatarPath)?.isAbsolute == true) {
                imageProvider = NetworkImage(avatarPath);
              } else {
                try {
                  imageProvider = MemoryImage(base64Decode(avatarPath));
                } catch (e) {
                  imageProvider = null;
                }
              }
            }

            return AppAnimations.fadeInFromBottom(ListView(
              padding: const EdgeInsets.all(AppTheme.defaultPadding),
              children: [
                const SizedBox(height: AppTheme.spaceL),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.secondary,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? Icon(Icons.person,
                            size: 50, color: theme.colorScheme.onSecondary)
                        : null,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                Center(
                  child: Text(
                    user?.name ?? 'Usuário',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXS),
                Center(
                  child: Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppTheme.spaceXS),
                    child: Center(
                      child: Text(
                        user.phoneNumber!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                const SizedBox(height: AppTheme.spaceXL),
                SettingsTile(
                  icon: Icons.category_outlined,
                  title: 'Gerenciar Categorias',
                  onTap: () {
                    NavigationUtils.push(context, const CategoriesScreen());
                  },
                ),
                const SizedBox(height: AppTheme.spaceS),
                SettingsTile(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Backup no Google Drive',
                  onTap: () => _showBackupDialog(context),
                ),
                const SizedBox(height: AppTheme.spaceS),
                SettingsTile(
                  icon: Icons.logout,
                  title: 'Sair do Aplicativo',
                  iconColor: theme.colorScheme.error,
                  textColor: theme.colorScheme.error,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("Confirmar Logout",
                            style: theme.textTheme.titleMedium),
                        content: Text("Deseja realmente sair do aplicativo?",
                            style: theme.textTheme.bodyMedium),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text("Cancelar",
                                style: theme.textTheme.labelLarge),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Provider.of<AuthViewModel>(context, listen: false)
                                  .logout(context);
                            },
                            child:
                                Text("Sair", style: theme.textTheme.labelLarge),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ));
          },
        ),
      ),
    );
  }
}
