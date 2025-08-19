import 'package:flutter/material.dart';
import 'package:key_budget/features/auth/view/login_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
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
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
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
