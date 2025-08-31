import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/user/view/edit_user_screen.dart';
import 'package:provider/provider.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

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
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user?.name ?? 'Usuário',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                Center(
                  child: Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                  Center(
                    child: Text(
                      user.phoneNumber!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
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
                              Provider.of<AuthViewModel>(context, listen: false)
                                  .logout(context);
                            },
                            child: const Text("Sair"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Sair'),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 250.ms);
        },
      ),
    );
  }
}
