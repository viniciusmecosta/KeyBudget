import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
            .fetchCredentials(authViewModel.currentUser!.id);
      }
    });
  }

  Future<void> _handleRefresh() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (mounted && authViewModel.currentUser != null) {
      await Provider.of<CredentialViewModel>(context, listen: false)
          .fetchCredentials(authViewModel.currentUser!.id);
    }
  }

  void _import(BuildContext context) async {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final count =
        await viewModel.importCredentialsFromCsv(authViewModel.currentUser!.id);
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('$count credenciais importadas com sucesso!'),
        backgroundColor: Colors.green));
  }

  void _export(BuildContext context) async {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = await viewModel.exportCredentialsToCsv();
    if (success) {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Credenciais exportadas com sucesso!'),
          backgroundColor: Colors.green));
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Falha ao exportar.'), backgroundColor: Colors.red));
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
        title: const Text('Minhas Credenciais'),
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
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            Expanded(
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
                                    builder: (_) =>
                                        const AddCredentialScreen())),
                          ),
                        ),
                      );
                    });
                  }
                  return ListView.builder(
                    itemCount: vm.allCredentials.length,
                    itemBuilder: (context, index) {
                      final credential = vm.allCredentials[index];
                      final logoPath = credential.logoPath;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              logoPath != null && logoPath.isNotEmpty
                                  ? MemoryImage(base64Decode(logoPath))
                                  : null,
                          child: logoPath == null || logoPath.isEmpty
                              ? const Icon(Icons.vpn_key_outlined)
                              : null,
                        ),
                        title: Text(credential.location),
                        subtitle: Text(credential.login),
                        trailing: IconButton(
                          icon: const Icon(Icons.visibility),
                          onPressed: () => _showDecryptedPassword(
                              context, credential.encryptedPassword),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CredentialDetailScreen(
                                  credential: credential),
                            ),
                          );
                        },
                      ).animate().fade(delay: (100 * index).ms).slideX();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddCredentialScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
