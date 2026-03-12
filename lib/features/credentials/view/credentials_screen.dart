import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/folder_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/add_credential_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/credentials/widgets/folder_list_tile.dart';
import 'package:provider/provider.dart';

import '../widgets/credential_list_tile.dart';
import '../widgets/credentials_list_skeleton.dart';

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        final credentialViewModel =
            Provider.of<CredentialViewModel>(context, listen: false);
        credentialViewModel.listKey = _listKey;
        credentialViewModel.listenToCredentials(authViewModel.currentUser!.id);
      }
    });
  }

  Future<void> _handleRefresh() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (mounted && authViewModel.currentUser != null) {
      Provider.of<CredentialViewModel>(context, listen: false)
          .listenToCredentials(authViewModel.currentUser!.id);
    }
  }

  void _import(BuildContext context) async {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    await viewModel.importCredentialsFromCsv(authViewModel.currentUser!.id);
    if (!context.mounted) return;
  }

  void _export(BuildContext context, {String type = 'csv'}) async {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);

    if (type == 'csv') {
      await viewModel.exportCredentialsToCsv(context);
      if (!context.mounted) return;
    } else if (type == 'pdf') {
      await viewModel.exportCredentialsToPdf(context);
    }
  }

  void _showCreateFolderDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Pasta'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome da Pasta',
            hintText: 'Ex: Bancos, Social',
          ),
          textCapitalization: TextCapitalization.sentences,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Provider.of<CredentialViewModel>(context, listen: false)
                    .createFolder(userId, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CredentialViewModel>();
    final theme = Theme.of(context);
    final authVm = context.read<AuthViewModel>();

    return PopScope(
      canPop: vm.currentFolderId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (vm.currentFolderId != null) {
          vm.exitFolder();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: vm.currentFolderId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => vm.exitFolder(),
                )
              : null,
          title: Text(vm.currentFolder?.name ?? 'Credenciais'),
          actions: [
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                    value: 'import', child: Text('Importar de CSV')),
                PopupMenuItem(
                  value: 'export_csv',
                  enabled: !vm.isExportingCsv && !vm.isExportingPdf,
                  child: Row(
                    children: [
                      const Text('Exportar para CSV'),
                      if (vm.isExportingCsv) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'export_pdf',
                  enabled: !vm.isExportingCsv && !vm.isExportingPdf,
                  child: Row(
                    children: [
                      const Text('Exportar para PDF'),
                      if (vm.isExportingPdf) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
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
          child: AppAnimations.fadeInFromBottom(
            RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (vm.isLoading)
                    const CredentialsListSkeleton()
                  else if (vm.currentDisplayItems.isEmpty)
                    SliverFillRemaining(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: EmptyStateWidget(
                          icon: vm.currentFolderId != null
                              ? Icons.folder_open
                              : Icons.key_off,
                          message: vm.currentFolderId != null
                              ? 'Esta pasta está vazia.'
                              : 'Nenhuma credencial ou pasta encontrada.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppTheme.defaultPadding,
                          AppTheme.spaceL,
                          AppTheme.defaultPadding,
                          96.0),
                      sliver: SliverAnimatedList(
                        key: _listKey,
                        initialItemCount: vm.currentDisplayItems.length,
                        itemBuilder: (context, index, animation) {
                          if (index >= vm.currentDisplayItems.length)
                            return const SizedBox.shrink();

                          final item = vm.currentDisplayItems[index];

                          if (item is Folder) {
                            return AnimatedListItem(
                              animation: animation,
                              child: FolderListTile(
                                key: ValueKey('folder_${item.id}'),
                                folder: item,
                                onTap: () => vm.enterFolder(item.id!),
                                onDelete: () => vm.deleteFolder(
                                    authVm.currentUser!.id, item.id!),
                              ),
                            );
                          } else if (item is Credential) {
                            return AnimatedListItem(
                              animation: animation,
                              child: CredentialListTile(
                                  key: ValueKey('cred_${item.id}'),
                                  credential: item),
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
        floatingActionButton:
            AppAnimations.scaleIn(FloatingActionButton.extended(
          heroTag: 'fab_credentials',
          onPressed: () {
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
                            context, const AddCredentialScreen());
                      },
                    ),
                    if (vm.currentFolderId == null)
                      ListTile(
                        leading: const Icon(Icons.create_new_folder),
                        title: const Text('Nova Pasta'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _showCreateFolderDialog(
                              context, authVm.currentUser!.id);
                        },
                      ),
                  ],
                ),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text("Novo"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
          ),
        )),
      ),
    );
  }
}
