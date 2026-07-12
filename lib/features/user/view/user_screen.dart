import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
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

import '../widgets/settings_tile.dart';

class ThemeColorOption {
  final String name;
  final int colorValue;

  const ThemeColorOption(this.name, this.colorValue);
}

const List<ThemeColorOption> _themeColors = [
  ThemeColorOption('Roxo (Padrão)', 0xFF1E40AF),
  ThemeColorOption('Azul', 0xFF2563EB),
  ThemeColorOption('Verde', 0xFF15803D),
  ThemeColorOption('Vermelho', 0xFFB91C1C),
  ThemeColorOption('Laranja', 0xFFC2410C),
  ThemeColorOption('Ciano', 0xFF0E7490),
  ThemeColorOption('Índigo', 0xFF4338CA),
  ThemeColorOption('Teal', 0xFF0F766E),
  ThemeColorOption('Vinho', 0xFF9F1239),
];

class UserScreen extends ConsumerWidget {
  const UserScreen({super.key});

  Future<void> _performBackup(
    BuildContext context,
    WidgetRef ref,
    bool exp,
    bool rec,
    bool cred,
    bool cat,
  ) async {
    try {
      final driveService = DriveService();
      final csvService = CsvService();

      final expVm = ref.read(expenseViewModelProvider);
      final credVm = ref.read(credentialViewModelProvider);
      final catVm = ref.read(categoryViewModelProvider);

      final dir = await getTemporaryDirectory();

      int successCount = 0;

      if (exp) {
        final csvStr = csvService.generateExpensesCsvString(expVm.allExpenses);
        final file = File('${dir.path}/despesas_backup.csv');
        await file.writeAsBytes(utf8.encode(csvStr));
        final res = await driveService.uploadFile(
          file,
          (p0, p1) {},
          isBackup: true,
        );
        if (res != null) successCount++;
      }

      if (rec) {
        final csvStr = csvService.generateRecurringExpensesCsvString(
          expVm.recurringExpenses,
        );
        final file = File('${dir.path}/despesas_recorrentes_backup.csv');
        await file.writeAsBytes(utf8.encode(csvStr));
        final res = await driveService.uploadFile(
          file,
          (p0, p1) {},
          isBackup: true,
        );
        if (res != null) successCount++;
      }

      if (cred) {
        final csvStr = csvService.generateCredentialsCsvString(
          credVm.allCredentials,
          credVm.decryptPassword,
        );
        final file = File('${dir.path}/credenciais_backup.csv');
        await file.writeAsBytes(utf8.encode(csvStr));
        final res = await driveService.uploadFile(
          file,
          (p0, p1) {},
          isBackup: true,
        );
        if (res != null) successCount++;
      }

      if (cat) {
        final csvStr = csvService.generateCategoriesCsvString(catVm.categories);
        final file = File('${dir.path}/categorias_backup.csv');
        await file.writeAsBytes(utf8.encode(csvStr));
        final res = await driveService.uploadFile(
          file,
          (p0, p1) {},
          isBackup: true,
        );
        if (res != null) successCount++;
      }

      if (context.mounted) {
        if (successCount > 0) {
          SnackbarService.showSuccess(
            context,
            'Backup de $successCount arquivo(s) concluído na pasta Backup do Drive!',
          );
        } else {
          SnackbarService.showError(
            context,
            'Nenhum arquivo foi salvo. Verifique sua conexão.',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarService.showError(context, 'Erro ao realizar backup: $e');
      }
    }
  }

  void _showBackupDialog(BuildContext context, WidgetRef ref) {
    bool backupExpenses = true;
    bool backupRecurring = true;
    bool backupCredentials = true;
    bool backupCategories = true;
    bool isBackingUp = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusVerticalXL,
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Backup no Google Drive',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione os dados que deseja exportar em formato CSV diretamente para o seu Drive.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CheckboxListTile(
                    title: const Text(
                      'Despesas',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: backupExpenses,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: isBackingUp
                        ? null
                        : (v) => setState(() => backupExpenses = v ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Despesas Recorrentes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: backupRecurring,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: isBackingUp
                        ? null
                        : (v) => setState(() => backupRecurring = v ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Credenciais',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: backupCredentials,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: isBackingUp
                        ? null
                        : (v) => setState(() => backupCredentials = v ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text(
                      'Categorias',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: backupCategories,
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: isBackingUp
                        ? null
                        : (v) => setState(() => backupCategories = v ?? true),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      onPressed:
                          isBackingUp ||
                              (!backupExpenses &&
                                  !backupRecurring &&
                                  !backupCredentials &&
                                  !backupCategories)
                          ? () {}
                          : () async {
                              setState(() => isBackingUp = true);
                              await _performBackup(
                                context,
                                ref,
                                backupExpenses,
                                backupRecurring,
                                backupCredentials,
                                backupCategories,
                              );
                              if (context.mounted) Navigator.pop(context);
                            },
                      isLoading: isBackingUp,
                      label: 'Iniciar Backup',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showThemeColorDialog(BuildContext context, WidgetRef ref) {
    final authViewModel = ref.read(authViewModelProvider);
    final user = authViewModel.currentUser;
    final currentThemeColor = user?.themeColor ?? _themeColors.first.colorValue;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusVerticalXL,
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Cor do Tema',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _themeColors.map((colorOption) {
                    final isSelected =
                        colorOption.colorValue == currentThemeColor;
                    return GestureDetector(
                      onTap: () async {
                        if (user != null) {
                          await authViewModel.updateUser(
                            name: user.name,
                            themeColor: colorOption.colorValue,
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color(colorOption.colorValue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            colorOption.name,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Meu Perfil', style: theme.textTheme.titleLarge),
      ),
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final authViewModel = ref.watch(authViewModelProvider);
            final user = authViewModel.currentUser;
            final avatarPath = user?.avatarPath;
            ImageProvider? imageProvider;

            String? formattedPhone = user?.phoneNumber;
            if (formattedPhone != null && formattedPhone.isNotEmpty) {
              final digits = formattedPhone.replaceAll(RegExp(r'\D'), '');
              if (digits.length == 11) {
                formattedPhone =
                    '(${digits.substring(0, 2)}) ${digits.substring(2, 3)}.${digits.substring(3, 7)}.${digits.substring(7, 11)}';
              } else if (digits.length == 10) {
                formattedPhone =
                    '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}.${digits.substring(6, 10)}';
              }
            }

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

            Widget buildSection(String title, List<Widget> children) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
                    child: Text(
                      title.toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppBorders.borderRadiusL,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(children: children),
                  ),
                ],
              );
            }

            return AppAnimations.fadeInFromBottom(
              ResponsiveCenter(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: imageProvider,
                          child: imageProvider == null
                              ? Icon(
                                  Icons.person,
                                  size: 36,
                                  color: theme.colorScheme.onPrimaryContainer,
                                )
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Usuário',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                user?.email ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (formattedPhone != null &&
                                  formattedPhone.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    formattedPhone,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    buildSection('Conta', [
                      SettingsTile(
                        icon: Icons.person_outline,
                        title: 'Editar Perfil',
                        subtitle: 'Atualize seu nome, telefone e senha',
                        onTap: () {
                          NavigationUtils.push(context, const EditUserScreen());
                        },
                      ),
                    ]),
                    buildSection('Preferências', [
                      SettingsTile(
                        icon: Icons.palette_outlined,
                        title: 'Cor do Tema',
                        subtitle: 'Personalize a cor principal',
                        onTap: () => _showThemeColorDialog(context, ref),
                      ),
                    ]),
                    buildSection('Módulos', [
                      SettingsTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Habilitar Receitas',
                        subtitle: 'Exibe entradas e saldo no painel principal',
                        trailing: Switch(
                          value: user?.enableIncomes ?? false,
                          activeTrackColor: theme.colorScheme.primary,
                          activeThumbColor: theme.colorScheme.onPrimary,
                          onChanged: (value) async {
                            if (user != null) {
                              await authViewModel.updateUser(
                                name: user.name,
                                enableIncomes: value,
                              );
                            }
                          },
                        ),
                        onTap: () async {
                          if (user != null) {
                            await authViewModel.updateUser(
                              name: user.name,
                              enableIncomes: !(user.enableIncomes ?? false),
                            );
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16),
                      SettingsTile(
                        icon: Icons.storefront_outlined,
                        title: 'Habilitar Fornecedores',
                        subtitle: 'Exibe o módulo de fornecedores',
                        trailing: Switch(
                          value: user?.enableSuppliers ?? false,
                          activeTrackColor: theme.colorScheme.primary,
                          activeThumbColor: theme.colorScheme.onPrimary,
                          onChanged: (value) async {
                            if (user != null) {
                              await authViewModel.updateUser(
                                name: user.name,
                                enableSuppliers: value,
                              );
                            }
                          },
                        ),
                        onTap: () async {
                          if (user != null) {
                            await authViewModel.updateUser(
                              name: user.name,
                              enableSuppliers: !(user.enableSuppliers ?? false),
                            );
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16),
                      SettingsTile(
                        icon: Icons.category_outlined,
                        title: 'Gerenciar Categorias',
                        onTap: () {
                          NavigationUtils.push(
                            context,
                            const CategoriesScreen(),
                          );
                        },
                      ),
                    ]),
                    buildSection('Segurança e Dados', [
                      SettingsTile(
                        icon: Icons.security_outlined,
                        title: 'Proteção do Aplicativo',
                        subtitle: 'Exigir biometria e bloquear capturas',
                        trailing: Switch(
                          value: user?.appLocked ?? true,
                          activeTrackColor: theme.colorScheme.primary,
                          activeThumbColor: theme.colorScheme.onPrimary,
                          onChanged: (value) async {
                            if (user != null) {
                              await authViewModel.updateUser(
                                name: user.name,
                                appLocked: value,
                              );
                            }
                          },
                        ),
                        onTap: () async {
                          if (user != null) {
                            await authViewModel.updateUser(
                              name: user.name,
                              appLocked: !(user.appLocked ?? true),
                            );
                          }
                        },
                      ),
                      Divider(height: 1, indent: 56, endIndent: 16),
                      SettingsTile(
                        icon: Icons.cloud_upload_outlined,
                        title: 'Backup no Google Drive',
                        subtitle: 'Exportar dados para CSV',
                        onTap: () => _showBackupDialog(context, ref),
                      ),
                    ]),
                    buildSection('Conta', [
                      SettingsTile(
                        icon: Icons.logout,
                        title: 'Sair do Aplicativo',
                        iconColor: theme.colorScheme.error,
                        textColor: theme.colorScheme.error,
                        trailing: const SizedBox.shrink(),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(
                                "Confirmar Logout",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                "Deseja realmente sair do aplicativo?",
                                style: theme.textTheme.bodyMedium,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    "Cancelar",
                                    style: theme.textTheme.labelLarge,
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    ref
                                        .read(authViewModelProvider)
                                        .logout(context, ref);
                                  },
                                  child: Text(
                                    "Sair",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.onError,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
