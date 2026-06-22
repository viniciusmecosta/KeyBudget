import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/credentials/view/credential_detail_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';

class CredentialListTile extends ConsumerWidget {
  final Credential credential;

  const CredentialListTile({super.key, required this.credential});

  void _showDecryptedPassword(
      BuildContext context, WidgetRef ref, String encryptedPassword) {
    final viewModel = ref.read(credentialViewModelProvider);
    final decryptedPassword = viewModel.decryptPassword(encryptedPassword);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock_open_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Senha'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A senha é:',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurface.withAlpha((255 * 0.05).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                decryptedPassword,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copiar Senha'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: decryptedPassword));
              HapticFeedback.lightImpact();
              SnackbarService.showSuccess(
                  context, 'Senha copiada para a área de transferência');
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final logoPath = credential.logoPath;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () {
        NavigationUtils.push(
            context, CredentialDetailScreen(credential: credential));
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: logoPath != null && logoPath.isNotEmpty
                ? Colors.transparent
                : theme.colorScheme.secondary
                    .withAlpha((255 * 0.1).round()),
            backgroundImage: logoPath != null && logoPath.isNotEmpty
                ? MemoryImage(base64Decode(logoPath))
                : null,
            child: logoPath == null || logoPath.isEmpty
                ? Icon(Icons.vpn_key_outlined,
                    color: theme.colorScheme.secondary, size: 24)
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
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            onPressed: () => _showDecryptedPassword(
                context, ref, credential.encryptedPassword),
          ),
        ],
      ),
    );
  }
}
