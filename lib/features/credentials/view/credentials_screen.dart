import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/add_credential_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/credential_list_tile.dart';

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

    final count =
        await viewModel.importCredentialsFromCsv(authViewModel.currentUser!.id);
    if (!mounted) return;
    SnackbarService.showSuccess(
        context, '$count credenciais importadas com sucesso!');
  }

  void _export(BuildContext context) async {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);

    final success = await viewModel.exportCredentialsToCsv();
    if (mounted) {
      if (success) {
        SnackbarService.showSuccess(
            context, 'Credenciais exportadas com sucesso!');
      } else {
        SnackbarService.showError(context, 'Falha ao exportar.');
      }
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
              const PopupMenuItem(
                  value: 'export', child: Text('Exportar para CSV')),
            ],
            onSelected: (value) {
              if (value == 'import') _import(context);
              if (value == 'export') _export(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: vm.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Carregando credenciais...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withAlpha((255 * 0.7).round()),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 300.ms),
              )
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    if (vm.allCredentials.isEmpty)
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
                        padding: const EdgeInsets.fromLTRB(
                            AppTheme.defaultPadding,
                            AppTheme.defaultPadding,
                            AppTheme.defaultPadding,
                            96.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final credential = vm.allCredentials[index];
                              Widget tile =
                                  CredentialListTile(credential: credential);
                              if (_isFirstLoad) {
                                return tile
                                    .animate(
                                        delay:
                                            Duration(milliseconds: 100 * index))
                                    .fadeIn(duration: 300.ms)
                                    .slideX(begin: 0.2, end: 0);
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
              }).fadeIn(duration: 250.ms),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_credentials',
        onPressed: () =>
            NavigationUtils.push(context, const AddCredentialScreen()),
        icon: const Icon(Icons.add),
        label: const Text("Nova Credencial"),
      ).animate().scale(duration: 250.ms),
    );
  }
}
