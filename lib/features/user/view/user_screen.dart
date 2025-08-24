import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/auth/view/login_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/user/view/edit_user_screen.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
              ],
            ),
          ),
        );
      },
    );
  }

  void _exportAllData(BuildContext context) async {
    _showLoadingDialog(context, "Exportando dados...");
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final credViewModel =
    Provider.of<CredentialViewModel>(context, listen: false);
    final expViewModel = Provider.of<ExpenseViewModel>(context, listen: false);

    final credSuccess = await credViewModel.exportCredentialsToCsv();
    final expSuccess = await expViewModel.exportExpensesToCsv(null, null);

    Navigator.of(context).pop();

    if (credSuccess && expSuccess) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Dados exportados com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Ocorreu um erro ao exportar os dados.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _importExpensesData(BuildContext context) async {
    _showLoadingDialog(context, "Importando despesas...");
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final expViewModel = Provider.of<ExpenseViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser!.id;

    final count = await expViewModel.importAllExpensesFromJson(userId);
    Navigator.of(context).pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(count > 0
            ? '$count despesas importadas com sucesso!'
            : 'Nenhuma despesa foi importada.'),
        backgroundColor: count > 0 ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _importCredentialsData(BuildContext context) async {
    _showLoadingDialog(context, "Importando credenciais...");
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final credViewModel =
    Provider.of<CredentialViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentUser!.id;

    final count = await credViewModel.importCredentialsFromJson(userId);
    Navigator.of(context).pop();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(count > 0
            ? '$count credenciais importadas com sucesso!'
            : 'Nenhuma credencial foi importada.'),
        backgroundColor: count > 0 ? Colors.green : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil e Configurações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditUserScreen()));
            },
          ),
        ],
      ),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          final user = authViewModel.currentUser;
          final avatarPath = user?.avatarPath;
          ImageProvider? imageProvider;

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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.secondary,
                      image: imageProvider != null
                          ? DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: imageProvider == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.8, end: 1.0),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user?.name ?? 'Usuário',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ).animate().fadeIn(delay: 100.ms, duration: 200.ms),
                Center(
                  child: Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 200.ms),
                if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                  Center(
                    child: Text(
                      user.phoneNumber!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 200.ms),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Confirmar Logout"),
                        content: const Text("Deseja realmente sair do aplicativo?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Cancelar"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Provider.of<AuthViewModel>(context, listen: false).logout();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                    (route) => false,
                              );
                            },
                            child: const Text("Sair"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Sair'),
                ).animate().fadeIn(delay: 400.ms, duration: 200.ms).scaleXY(begin: 0.9, end: 1.0),

              ],
            ),
          );
        },
      ),
    );
  }
}