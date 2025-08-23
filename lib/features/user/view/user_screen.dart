import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:key_budget/features/auth/view/login_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/user/view/edit_user_screen.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  void _exportAllData(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final credViewModel =
    Provider.of<CredentialViewModel>(context, listen: false);
    final expViewModel = Provider.of<ExpenseViewModel>(context, listen: false);

    final credSuccess = await credViewModel.exportCredentialsToCsv();
    final expSuccess = await expViewModel.exportExpensesToCsv(null, null);

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
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user?.name ?? 'Usuário',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Center(
                  child: Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                  Center(
                    child: Text(
                      user.phoneNumber!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar Meus Dados (CSV)'),
                  onPressed: () => _exportAllData(context),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () {
                    Provider.of<AuthViewModel>(context, listen: false).logout();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  },
                  child: const Text('Sair'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}