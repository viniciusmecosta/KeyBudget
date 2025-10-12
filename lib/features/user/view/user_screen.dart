import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/view/categories_screen.dart';
import 'package:key_budget/features/user/view/edit_user_screen.dart';
import 'package:provider/provider.dart';

import '../widgets/settings_tile.dart';

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
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              NavigationUtils.push(context, const EditUserScreen());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<AuthViewModel>(
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

            return ListView(
              padding: const EdgeInsets.all(AppTheme.defaultPadding),
              children: [
                const SizedBox(height: 20),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.secondary,
                    backgroundImage: imageProvider,
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
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    user?.email ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Center(
                      child: Text(
                        user.phoneNumber!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                SettingsTile(
                  icon: Icons.category_outlined,
                  title: 'Gerenciar Categorias',
                  onTap: () {
                    NavigationUtils.push(context, const CategoriesScreen());
                  },
                ),
                const SizedBox(height: 8),
                SettingsTile(
                  icon: Icons.logout,
                  title: 'Sair do Aplicativo',
                  iconColor: theme.colorScheme.error,
                  textColor: theme.colorScheme.error,
                  onTap: () {
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
                ),
              ],
            ).animate().fadeIn(duration: 250.ms);
          },
        ),
      ),
    );
  }
}
