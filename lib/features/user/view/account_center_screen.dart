import 'package:passfin/core/design_system/widgets/app_card.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/app/utils/navigation_utils.dart';
import 'package:passfin/app/widgets/responsive_center.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/core/design_system/widgets/app_feedback_panel.dart';
import 'package:passfin/core/services/snackbar_service.dart';
import 'package:passfin/features/auth/repository/auth_repository.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/features/user/view/backup_restore_screen.dart';

class AccountCenterScreen extends ConsumerStatefulWidget {
  const AccountCenterScreen({super.key});

  @override
  ConsumerState<AccountCenterScreen> createState() =>
      _AccountCenterScreenState();
}

class _AccountCenterScreenState extends ConsumerState<AccountCenterScreen> {
  bool _busy = false;

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).getCurrentFirebaseUser()?.reload();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Não foi possível atualizar a conta.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendVerification() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final account = ref.read(authRepositoryProvider).getCurrentFirebaseUser();
      if (account == null || account.email == null || account.emailVerified) {
        return;
      }
      await account.sendEmailVerification();
      if (mounted) {
        SnackbarService.showSuccess(
          context,
          'Enviamos um link de verificação para seu email.',
        );
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Não foi possível enviar o link. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await ref
          .read(authViewModelProvider)
          .sendPasswordResetEmail(email);
      if (mounted) {
        if (result.isSuccess) {
          SnackbarService.showSuccess(
            context,
            'Confira seu email para redefinir a senha.',
          );
        } else {
          SnackbarService.showError(
            context,
            result.safeError ??
                'Não foi possível enviar o link. Tente novamente.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authViewModelProvider).currentUser;
    if (profile == null) {
      return AppPageScaffold(
        appBar: AppBar(title: const Text('Conta e recuperação')),
        body: const AppFeedbackPanel(
          title: 'Sessão encerrada',
          message: 'Entre novamente para acessar os dados da conta.',
        ),
      );
    }
    final account = ref.read(authRepositoryProvider).getCurrentFirebaseUser();
    final providers =
        account?.providerData.map((item) => item.providerId).toSet() ??
        <String>{};
    final email = account?.email ?? profile.email;
    final hasPassword = providers.contains('password');
    final hasGoogle = providers.contains('google.com');
    final method = hasPassword && hasGoogle
        ? 'Email e Google'
        : hasGoogle
        ? 'Google'
        : 'Email e senha';
    final theme = Theme.of(context);

    return AppPageScaffold(
      appBar: AppBar(title: const Text('Conta e recuperação')),
      body: ResponsiveCenter(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.alternate_email),
                    title: const Text('Email da conta'),
                    subtitle: Text(email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.login_outlined),
                    title: const Text('Forma de acesso'),
                    subtitle: Text(method),
                  ),
                  if (account != null && email.isNotEmpty) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        account.emailVerified
                            ? Icons.verified_outlined
                            : Icons.mark_email_unread_outlined,
                        color: account.emailVerified
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        account.emailVerified
                            ? 'Email verificado'
                            : 'Email ainda não verificado',
                      ),
                      trailing: IconButton(
                        tooltip: 'Atualizar verificação',
                        onPressed: _busy ? null : _refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (account != null && !account.emailVerified && email.isNotEmpty)
              FilledButton.icon(
                onPressed: _busy ? null : _sendVerification,
                icon: const Icon(Icons.mark_email_read_outlined),
                label: const Text('Enviar link de verificação'),
              ),
            if (hasPassword && email.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _sendPasswordReset(email),
                icon: const Icon(Icons.password_outlined),
                label: const Text('Redefinir senha por email'),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () =>
                  NavigationUtils.push(context, const BackupRestoreScreen()),
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Acessar backup e restauração'),
            ),
          ],
        ),
      ),
    );
  }
}
