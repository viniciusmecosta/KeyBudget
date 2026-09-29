import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class DashboardHeader extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onCustomize;

  const DashboardHeader({super.key, this.onCustomize});

  ImageProvider? _getAvatarProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (Uri.tryParse(path)?.isAbsolute == true) {
      return NetworkImage(path);
    }
    try {
      return MemoryImage(base64Decode(path));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authViewModelProvider).currentUser;

    final hour = DateTime.now().hour;
    final String greeting;
    if (hour >= 5 && hour < 12) {
      greeting = 'Bom dia,';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Boa tarde,';
    } else {
      greeting = 'Boa noite,';
    }

    final userName = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'Usuário';

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: 72,
      title: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                label: '$greeting $userName',
                child: ExcludeSemantics(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$greeting ',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: userName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (onCustomize != null)
              IconButton(
                tooltip: 'Personalizar painel',
                onPressed: onCustomize,
                icon: const Icon(Icons.tune_rounded),
              ),
            Semantics(
              button: true,
              label: 'Abrir perfil',
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  ref
                      .read(navigationViewModelProvider)
                      .navigateTo(AppDestination.profile);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withAlpha(25),
                    backgroundImage: _getAvatarProvider(user?.avatarPath),
                    child:
                        (user?.avatarPath == null || user!.avatarPath!.isEmpty)
                        ? Icon(Icons.person, color: theme.colorScheme.primary)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(88.0);
}
