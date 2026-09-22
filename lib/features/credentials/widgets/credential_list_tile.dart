import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/features/credentials/view/credential_detail_screen.dart';

class CredentialListTile extends ConsumerWidget {
  final Credential credential;

  const CredentialListTile({super.key, required this.credential});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logoPath = credential.logoPath;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        NavigationUtils.push(
          context,
          CredentialDetailScreen(credential: credential),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: logoPath != null && logoPath.isNotEmpty
                ? Colors.transparent
                : theme.colorScheme.secondary.withAlpha((255 * 0.1).round()),
            backgroundImage: logoPath != null && logoPath.isNotEmpty
                ? MemoryImage(base64Decode(logoPath))
                : null,
            child: logoPath == null || logoPath.isEmpty
                ? Icon(
                    Icons.vpn_key_outlined,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  credential.location,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  minFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  credential.login,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  minFontSize: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
