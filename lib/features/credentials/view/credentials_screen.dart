import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
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
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        Provider.of<CredentialViewModel>(context, listen: false)
            .listenToCredentials(authViewModel.currentUser!.id);
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
    final scaffoldContext = context;

    final count =
        await viewModel.importCredentialsFromCsv(authViewModel.currentUser!.id);
    if (!scaffoldContext.mounted) return;
    SnackbarService.showSuccess(
        scaffoldContext, '$count credenciais importadas com sucesso!');
  }

  void _export(BuildContext context, {String type = 'csv'}) async {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
    final scaffoldContext = context;

    bool success = false;
    if (type == 'csv') {
      success = await viewModel.exportCredentialsToCsv(scaffoldContext);
      if (!scaffoldContext.mounted) return;
      if (success) {
        SnackbarService.showSuccess(
            scaffoldContext, 'Credenciais exportadas com sucesso!');
      } else if (!viewModel.isExportingCsv) {
        SnackbarService.showError(scaffoldContext, 'Falha ao exportar.');
      }
    } else if (type == 'pdf') {
      await viewModel.exportCredentialsToPdf(scaffoldContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CredentialViewModel>();
    final theme = Theme.of(context);
    final isLoading = vm.isLoading && _isFirstLoad;

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
              if (isLoading)
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
                      AppTheme.defaultPadding, AppTheme.defaultPadding, 96.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final credential = vm.allCredentials[index];
                        Widget tile =
                            CredentialListTile(credential: credential);
                        if (_isFirstLoad) {
                          return AppAnimations.listFadeIn(tile, index: index);
                        }
                        return tile;
                      },
                      childCount: vm.allCredentials.length,
                    ),
                  ),
                ),
            ],
          ),
        ).animate(onComplete: (_) {
          if (_isFirstLoad && mounted) {
            setState(() {
              _isFirstLoad = false;
            });
          }
        }).fadeIn(duration: AppAnimations.duration),
      ),
      floatingActionButton: AppAnimations.scaleIn(FloatingActionButton.extended(
        heroTag: 'fab_credentials',
        onPressed: () =>
            NavigationUtils.push(context, const AddCredentialScreen()),
        icon: const Icon(Icons.add),
        label: const Text("Nova Credencial"),
      )),
    );
  }
}
