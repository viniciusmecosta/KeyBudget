import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/features/credentials/view/credential_detail_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:provider/provider.dart';

class CredentialListTile extends StatelessWidget {
  final Credential credential;

  const CredentialListTile({super.key, required this.credential});

  void _showDecryptedPassword(BuildContext context, String encryptedPassword) {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
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
                color: theme.colorScheme.onSurface.withOpacity(0.05),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Senha copiada para a área de transferência'),
                    behavior: SnackBarBehavior.floating),
              );
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoPath = credential.logoPath;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CredentialDetailScreen(credential: credential),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: logoPath != null && logoPath.isNotEmpty
                      ? Colors.transparent
                      : theme.colorScheme.secondary.withOpacity(0.1),
                  backgroundImage: logoPath != null && logoPath.isNotEmpty
                      ? MemoryImage(base64Decode(logoPath))
                      : null,
                  child: logoPath == null || logoPath.isEmpty
                      ? Icon(Icons.vpn_key_outlined,
                          color: theme.colorScheme.secondary, size: 24)
                      : null,
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credential.location,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AutoSizeText(
                        credential.login,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                      context, credential.encryptedPassword),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
