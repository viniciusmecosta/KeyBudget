import 'dart:convert';

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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Senha Decifrada'),
        content: Text(decryptedPassword),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: decryptedPassword));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Senha copiada para a área de transferência')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Copiar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Consumer<CredentialViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.allCredentials.isEmpty) {
                return LayoutBuilder(builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: EmptyStateWidget(
                        icon: Icons.key_off,
                        message: 'Nenhuma credencial encontrada.',
                        buttonText: 'Adicionar Credencial',
                        onButtonPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const AddCredentialScreen())),
                      ),
                    ),
                  );
                });
              }
              return ListView.builder(
                padding: const EdgeInsets.all(AppTheme.defaultPadding),
                itemCount: vm.allCredentials.length,
                itemBuilder: (context, index) {
                  final credential = vm.allCredentials[index];
                  final logoPath = credential.logoPath;
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.15),
                        backgroundImage: logoPath != null && logoPath.isNotEmpty
                            ? MemoryImage(base64Decode(logoPath))
                            : null,
                        child: logoPath == null || logoPath.isEmpty
                            ? Icon(Icons.vpn_key_outlined,
                                color: Theme.of(context).colorScheme.secondary)
                            : null,
                      ),
                      title: Text(credential.location,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(credential.login),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        onPressed: () => _showDecryptedPassword(
                            context, credential.encryptedPassword),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CredentialDetailScreen(credential: credential),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ).animate().fadeIn(duration: 250.ms),
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
}
