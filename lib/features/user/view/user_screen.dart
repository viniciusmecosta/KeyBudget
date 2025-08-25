import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/user/view/edit_user_screen.dart';
import 'package:provider/provider.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

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
    final theme = Theme.of(context);
    final credViewModel =
        Provider.of<CredentialViewModel>(context, listen: false);
    final expViewModel = Provider.of<ExpenseViewModel>(context, listen: false);

    final credSuccess = await credViewModel.exportCredentialsToCsv();
    final expSuccess = await expViewModel.exportExpensesToCsv(null, null);

    Navigator.of(context).pop();

    if (credSuccess && expSuccess) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Dados exportados com sucesso!'),
          backgroundColor: theme.colorScheme.secondaryContainer,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Ocorreu um erro ao exportar os dados.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  void _importExpensesData(BuildContext context) async {
    _showLoadingDialog(context, "Importando despesas...");
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
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
        backgroundColor: count > 0
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.error,
      ),
    );
  }

  void _importCredentialsData(BuildContext context) async {
    _showLoadingDialog(context, "Importando credenciais...");
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
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
        backgroundColor: count > 0
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
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
                      color: theme.colorScheme.secondary,
                      image: imageProvider != null
                          ? DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageProvider == null
                        ? Icon(Icons.person,
                            size: 50, color: theme.colorScheme.onSecondary)
                        : null,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 160.ms)
                    .scaleXY(begin: 0.8, end: 1.0)
                    .shimmer(duration: 600.ms, delay: 200.ms),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user?.name ?? 'Usuário',
                    style: theme.textTheme.headlineSmall,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 160.ms)
                    .slideX(begin: -0.1, end: 0),
                Center(
                  child: Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 160.ms)
                    .slideX(begin: -0.1, end: 0),
                if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                  Center(
                    child: Text(
                      user.phoneNumber!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 240.ms, duration: 160.ms)
                      .slideX(begin: -0.1, end: 0),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Confirmar Logout"),
                        content:
                            const Text("Deseja realmente sair do aplicativo?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text("Cancelar"),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();

                              Provider.of<DashboardViewModel>(context,
                                      listen: false)
                                  .clearData();
                              Provider.of<ExpenseViewModel>(context,
                                      listen: false)
                                  .clearData();
                              Provider.of<CredentialViewModel>(context,
                                      listen: false)
                                  .clearData();
                              Provider.of<NavigationViewModel>(context,
                                      listen: false)
                                  .clearData();

                              Provider.of<AuthViewModel>(context, listen: false)
                                  .logout();
                            },
                            child: const Text("Sair"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Sair'),
                )
                    .animate()
                    .fadeIn(delay: 320.ms, duration: 160.ms)
                    .scaleXY(begin: 0.9, end: 1.0)
                    .shake(hz: 3, duration: 300.ms),
              ],
            ),
          );
        },
      ),
    );
  }
}
