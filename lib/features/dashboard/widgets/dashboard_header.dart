import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class DashboardHeader extends StatelessWidget implements PreferredSizeWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<AuthViewModel>(context).currentUser;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: 80,
      title: Padding(
        padding: const EdgeInsets.only(top: AppTheme.spaceS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo(a) de volta,',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              user?.name ?? 'Usuário',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}
