import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/view/add_credential_screen.dart';
import 'package:key_budget/features/credentials/view/credential_detail_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:provider/provider.dart';

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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final count =
        await viewModel.importCredentialsFromCsv(authViewModel.currentUser!.id);
    if (!mounted) return;
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('$count credenciais importadas com sucesso!'),
        backgroundColor: theme.colorScheme.secondaryContainer));
  }

  void _export(BuildContext context) async {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final success = await viewModel.exportCredentialsToCsv();
    if (success) {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: const Text('Credenciais exportadas com sucesso!'),
          backgroundColor: theme.colorScheme.secondaryContainer));
    } else {
      scaffoldMessenger.showSnackBar(SnackBar(
          content: const Text('Falha ao exportar.'),
          backgroundColor: theme.colorScheme.error));
    }
  }

  void _showDecryptedPassword(BuildContext context, String encryptedPassword) {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
    final decryptedPassword = viewModel.decryptPassword(encryptedPassword);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_open_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Senha'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A senha é:',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                decryptedPassword,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar Senha'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: decryptedPassword));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Senha copiada para a área de transferência'),
                    behavior: SnackBarBehavior.floating),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
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
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                          child: EmptyStateWidget(
                            icon: Icons.key_off,
                            message: 'Nenhuma credencial encontrada.',
                            buttonText: 'Adicionar Credencial',
                            onButtonPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AddCredentialScreen())),
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
                              return _buildCredentialTile(
                                  context, credential, index);
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
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddCredentialScreen())),
        icon: const Icon(Icons.add),
        label: const Text("Nova Credencial"),
      ).animate().scale(duration: 250.ms),
    );
  }

  Widget _buildCredentialTile(
      BuildContext context, dynamic credential, int index) {
    final theme = Theme.of(context);
    final logoPath = credential.logoPath;

    Widget tile = Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CredentialDetailScreen(credential: credential),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: logoPath != null && logoPath.isNotEmpty
                      ? Colors.transparent
                      : theme.colorScheme.secondary.withOpacity(0.1),
                  backgroundImage: logoPath != null && logoPath.isNotEmpty
                      ? MemoryImage(base64Decode(logoPath))
                      : null,
                  child: logoPath == null || logoPath.isEmpty
                      ? Icon(Icons.vpn_key_outlined,
                          color: theme.colorScheme.secondary, size: 24)
                      : null,
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credential.location,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AutoSizeText(
                        credential.login,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        minFontSize: 10,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => _showDecryptedPassword(
                      context, credential.encryptedPassword),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (_isFirstLoad) {
      return tile
          .animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.2, end: 0);
    }

    return tile;
  }
}
