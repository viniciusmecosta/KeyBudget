import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class DashboardHeader extends ConsumerWidget implements PreferredSizeWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authViewModelProvider).currentUser;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: 80,
      title: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bem-vindo(a) de volta,',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
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
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primary.withAlpha(25),
              backgroundImage: user?.avatarPath != null
                  ? NetworkImage(user!.avatarPath!)
                  : null,
              child: user?.avatarPath == null
                  ? Icon(Icons.person, color: theme.colorScheme.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80.0);
}
