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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        final credentialViewModel =
            Provider.of<CredentialViewModel>(context, listen: false);
        credentialViewModel.setListKey(_listKey);
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
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (mounted && authViewModel.currentUser != null) {
      Provider.of<CredentialViewModel>(context, listen: false)
          .listenToCredentials(authViewModel.currentUser!.id);
    }
  }

  void _import(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Importando credenciais...'),
          ],
        ),
      ),
    );

    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    await viewModel.importCredentialsFromCsv(authViewModel.currentUser!.id);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _export(BuildContext context, {String type = 'csv'}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(type == 'csv' ? 'Gerando CSV...' : 'Gerando PDF...'),
          ],
        ),
      ),
    );

    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);

    if (type == 'csv') {
      await viewModel.exportCredentialsToCsv(context);
    } else if (type == 'pdf') {
      await viewModel.exportCredentialsToPdf(context);
    }

    if (context.mounted) {
      Navigator.of(context).pop();
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
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _isSearching
                ? Container(
                    key: const ValueKey('searchBox'),
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      textAlignVertical: TextAlignVertical.center,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Buscar credenciais...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  vm.setSearchQuery('');
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) => vm.setSearchQuery(val),
                    ),
                  )
                : Text(vm.currentFolder?.name ?? 'Credenciais',
                    key: const ValueKey('titleText')),
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
                        Icon(Icons.upload_file_rounded,
                            size: 18, color: theme.colorScheme.onSurface),
                        const SizedBox(width: AppTheme.spaceS),
                        const Text('Importar de CSV'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_csv',
                    child: Row(
                      children: [
                        Icon(Icons.grid_on,
                            size: 18, color: theme.colorScheme.onSurface),
                        const SizedBox(width: AppTheme.spaceS),
                        const Text('Exportar para CSV'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf,
                            size: 18, color: theme.colorScheme.onSurface),
                        const SizedBox(width: AppTheme.spaceS),
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
          child: AppAnimations.fadeInFromBottom(
            RefreshIndicator(
              onRefresh: _handleRefresh,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
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
                          if (index >= vm.currentDisplayItems.length) {
                            return const SizedBox.shrink();
                          }

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
