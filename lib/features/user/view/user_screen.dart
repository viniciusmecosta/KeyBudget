import 'dart:io';
import 'package:flutter/material.dart';
import 'package:key_budget/core/services/database_management_service.dart';
import 'package:key_budget/features/auth/view/login_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  void _exportDatabase(BuildContext context) async {
    final managementService = DatabaseManagementService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    bool success = await managementService.exportDatabase();

    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Backup salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Falha ao exportar. Verifique as permissões.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showImportDialog(BuildContext context) {
    final confirmationController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Atenção! Ação Irreversível'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Importar um banco de dados substituirá TODOS os seus dados atuais. Esta ação não pode ser desfeita.\n\nPara confirmar, digite "CONFIRMAR" no campo abaixo.'),
            const SizedBox(height: 16),
            TextField(
              controller: confirmationController,
              decoration: const InputDecoration(
                labelText: 'Digite para confirmar',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Importar'),
            onPressed: () {
              if (confirmationController.text == 'CONFIRMAR') {
                Navigator.of(ctx).pop();
                _importDatabase(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void _importDatabase(BuildContext context) async {
    final managementService = DatabaseManagementService();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final result = await managementService.importDatabase();

    switch (result) {
      case ImportResult.success:
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content:
                Text('Banco de dados importado! Por favor, reinicie o app.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        break;
      case ImportResult.failure:
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text(
                'Falha na importação. O arquivo pode estar corrompido ou a senha ser inválida.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        break;
      case ImportResult.noFileSelected:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil e Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user?.avatarPath != null
                  ? FileImage(File(user!.avatarPath!))
                  : null,
              child: user?.avatarPath == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
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
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar Banco de Dados'),
              onPressed: () => _showImportDialog(context),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Exportar Banco de Dados'),
              onPressed: () => _exportDatabase(context),
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
      ),
    );
  }
}
