import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/widgets/animated_item_sliver.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/widgets/app_search_field.dart';
import 'package:key_budget/core/design_system/widgets/app_color_choice.dart';
import 'package:key_budget/core/design_system/widgets/app_feedback_panel.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/folder_model.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/add_credential_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/credentials/widgets/folder_list_tile.dart';

import '../widgets/credential_list_tile.dart';
import '../widgets/credentials_list_skeleton.dart';

class CredentialsScreen extends ConsumerStatefulWidget {
  const CredentialsScreen({super.key});

  @override
  ConsumerState<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends ConsumerState<CredentialsScreen> {
  bool _isSearching = false;
  bool _isProcessing = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = ref.read(authViewModelProvider);
      if (authViewModel.currentUser != null) {
        final credentialViewModel = ref.read(credentialViewModelProvider);
        credentialViewModel.listenToCredentials(authViewModel.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    final authViewModel = ref.read(authViewModelProvider);
    if (mounted && authViewModel.currentUser != null) {
      ref
          .read(credentialViewModelProvider)
          .retryListenToCredentials(authViewModel.currentUser!.id);
    }
  }

  void _import(BuildContext context) async {
    setState(() => _isProcessing = true);

    final viewModel = ref.read(credentialViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider);
    final appLock = ref.read(appLockServiceProvider);

    appLock.beginExternalPick();
    try {
      await viewModel.importCredentialsFromCsv(
        authViewModel.currentUser!.id,
        context: context,
      );
    } finally {
      appLock.endExternalPick();
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _export(BuildContext context, {String type = 'csv'}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exportar credenciais?'),
        content: Text(
          type == 'csv'
              ? 'O arquivo CSV inclui as senhas em texto legível. Compartilhe somente com um destino confiável e apague a cópia quando terminar.'
              : 'O relatório PDF pode incluir dados das suas credenciais. Compartilhe somente com um destino confiável.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !context.mounted) return;
    setState(() => _isProcessing = true);
    try {
      final viewModel = ref.read(credentialViewModelProvider);
      if (type == 'csv') {
        await viewModel.exportCredentialsToCsv(context);
      } else if (type == 'pdf') {
        await viewModel.exportCredentialsToPdf(context);
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showCreateFolderDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    int selectedColorValue = 0xFF3B82F6;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: AppBorders.borderRadiusXL,
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.create_new_folder_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Nova Pasta',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Nome da Pasta',
                      hintText: 'Ex: Bancos, Social',
                      prefixIcon: const Icon(Icons.folder_outlined),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: AppBorders.borderRadiusM,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Cor de Destaque',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: AppColorChoice.palette.entries
                        .map(
                          (entry) => AppColorChoice(
                            color: Color(entry.key),
                            label: 'Cor ${entry.value} da pasta',
                            selected: selectedColorValue == entry.key,
                            onPressed: () =>
                                setState(() => selectedColorValue = entry.key),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      ref
                          .read(credentialViewModelProvider)
                          .createFolder(
                            userId,
                            name,
                            color: selectedColorValue.toString(),
                          )
                          .then((_) {
                            if (context.mounted) Navigator.of(context).pop();
                          });
                    }
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Criar Pasta',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(credentialViewModelProvider);
    final theme = Theme.of(context);
    final authVm = ref.read(authViewModelProvider);

    return PopScope(
      canPop: vm.currentFolderId == null && !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
            vm.setSearchQuery('');
          });
          return;
        }
        if (vm.currentFolderId != null) {
          vm.exitFolder();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: (_isSearching || vm.currentFolderId != null)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (_isSearching) {
                      setState(() {
                        _isSearching = false;
                        _searchController.clear();
                        vm.setSearchQuery('');
                      });
                    } else if (vm.currentFolderId != null) {
                      vm.exitFolder();
                    }
                  },
                )
              : null,
          title: AnimatedSwitcher(
            duration: AppAnimations.durationFor(
              context,
              const Duration(milliseconds: 300),
            ),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _isSearching
                ? AppSearchField(
                    controller: _searchController,
                    hint: 'Buscar credenciais...',
                    onChanged: vm.setSearchQuery,
                    onClear: () {
                      _searchController.clear();
                      vm.setSearchQuery('');
                    },
                  )
                : Text(
                    vm.currentFolder?.name ?? 'Credenciais',
                    key: const ValueKey('titleText'),
                  ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: _isProcessing
                ? const LinearProgressIndicator()
                : const SizedBox(height: 4),
          ),
          actions: [
            if (!_isSearching)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
              ),
            if (!_isSearching)
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(
                          Icons.upload_file_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Importar de CSV'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_csv',
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_on,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Exportar para CSV'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_pdf',
                    child: Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('Exportar para PDF'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'import') _import(context);
                  if (value == 'export_csv') _export(context, type: 'csv');
                  if (value == 'export_pdf') _export(context, type: 'pdf');
                },
              ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.surface,
            child: ResponsiveCenter(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  if (vm.isLoading)
                    const CredentialsListSkeleton()
                  else if (vm.loadErrorMessage != null &&
                      vm.currentDisplayItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppFeedbackPanel(
                        title: 'Falha ao carregar o cofre',
                        message: vm.loadErrorMessage!,
                        type: AppFeedbackType.error,
                        actionLabel: 'Tentar novamente',
                        onAction: () {
                          final user = ref
                              .read(authViewModelProvider)
                              .currentUser;
                          if (user != null) {
                            vm.retryListenToCredentials(user.id);
                          }
                        },
                      ),
                    )
                  else if (vm.currentDisplayItems.isEmpty)
                    SliverFillRemaining(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: EmptyStateWidget(
                          icon: _isSearching || vm.searchQuery.isNotEmpty
                              ? Icons.search_off_outlined
                              : (vm.currentFolderId != null
                                    ? Icons.folder_open_outlined
                                    : Icons.key_off_outlined),
                          message: _isSearching || vm.searchQuery.isNotEmpty
                              ? 'Nenhuma credencial encontrada para a busca'
                              : (vm.currentFolderId != null
                                    ? 'Esta pasta está vazia'
                                    : 'Nenhuma credencial encontrada'),
                          buttonText: _isSearching || vm.searchQuery.isNotEmpty
                              ? 'Limpar busca'
                              : (vm.currentFolderId != null
                                    ? 'Adicionar credencial'
                                    : 'Nova credencial'),
                          onButtonPressed: () {
                            if (_isSearching || vm.searchQuery.isNotEmpty) {
                              setState(() {
                                _isSearching = false;
                                _searchController.clear();
                                vm.setSearchQuery('');
                              });
                            } else {
                              NavigationUtils.push(
                                context,
                                const AddCredentialScreen(),
                              );
                            }
                          },
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.md,
                        96.0,
                      ),
                      sliver: AnimatedItemSliver<dynamic>(
                        items: vm.currentDisplayItems,
                        identity: (item) => item is Folder
                            ? 'folder_${item.id}'
                            : 'credential_${(item as Credential).id}',
                        itemBuilder: (context, item) {
                          if (item is Folder) {
                            return FolderListTile(
                              key: ValueKey('folder_${item.id}'),
                              folder: item,
                              onTap: () => vm.enterFolder(item.id!),
                              onDelete: () => vm.deleteFolder(
                                authVm.currentUser!.id,
                                item.id!,
                              ),
                            );
                          } else if (item is Credential) {
                            return CredentialListTile(
                              key: ValueKey('cred_${item.id}'),
                              credential: item,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_credentials',
          onPressed: () {
            if (vm.currentFolderId != null) {
              NavigationUtils.push(context, const AddCredentialScreen());
            } else {
              showModalBottomSheet(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.key),
                        title: const Text('Nova Credencial'),
                        onTap: () {
                          Navigator.pop(ctx);
                          NavigationUtils.push(
                            context,
                            const AddCredentialScreen(),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.create_new_folder),
                        title: const Text('Nova Pasta'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showCreateFolderDialog(
                            context,
                            authVm.currentUser!.id,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.add),
          label: const Text("Novo"),
          shape: RoundedRectangleBorder(
            borderRadius: AppBorders.borderRadiusXXL,
          ),
        ),
      ),
    );
  }
}
