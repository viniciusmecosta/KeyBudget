import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/add_credential_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CredentialViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credenciais'),
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
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (vm.isLoading)
                const CredentialsListSkeleton()
              else if (vm.allCredentials.isEmpty)
                SliverFillRemaining(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: const EmptyStateWidget(
                      icon: Icons.key_off,
                      message: 'Nenhuma credencial encontrada.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.defaultPadding,
                      AppTheme.spaceL, AppTheme.defaultPadding, 96.0),
                  sliver: SliverAnimatedList(
                    key: _listKey,
                    initialItemCount: vm.allCredentials.length,
                    itemBuilder: (context, index, animation) {
                      final credential = vm.allCredentials[index];
                      return AnimatedListItem(
                        animation: animation,
                        child: CredentialListTile(
                            key: ValueKey(credential), credential: credential),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: AppAnimations.scaleIn(FloatingActionButton.extended(
        heroTag: 'fab_credentials',
        onPressed: () =>
            NavigationUtils.push(context, const AddCredentialScreen()),
        icon: const Icon(Icons.add),
        label: const Text("Nova Credencial"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXXL),
        ),
      )),
    );
  }
}
