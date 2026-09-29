import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class ExpenseSyncIndicator extends StatelessWidget {
  final ExpenseSyncStatus status;
  final DateTime? lastServerConfirmation;
  final VoidCallback? onRetry;

  const ExpenseSyncIndicator({
    super.key,
    required this.status,
    this.lastServerConfirmation,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ExpenseSyncStatus.loading) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final (icon, message, color) = switch (status) {
      ExpenseSyncStatus.cached => (
        Icons.cloud_off_outlined,
        'Dados em cache. Aguardando conexão.',
        theme.colorScheme.onSurfaceVariant,
      ),
      ExpenseSyncStatus.pending => (
        Icons.cloud_upload_outlined,
        'Alterações aguardando confirmação.',
        theme.colorScheme.tertiary,
      ),
      ExpenseSyncStatus.failed => (
        Icons.sync_problem_rounded,
        'Falha ao sincronizar os lançamentos.',
        theme.colorScheme.error,
      ),
      ExpenseSyncStatus.synced => (
        Icons.cloud_done_outlined,
        lastServerConfirmation == null
            ? 'Sincronizado com o servidor.'
            : 'Sincronizado às ${DateFormat.Hm('pt_BR').format(lastServerConfirmation!)}.',
        theme.colorScheme.primary,
      ),
      ExpenseSyncStatus.loading => throw StateError('Estado de carregamento.'),
    };

    return Semantics(
      liveRegion: status != ExpenseSyncStatus.synced,
      label: message,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
            if (onRetry != null &&
                (status == ExpenseSyncStatus.failed ||
                    status == ExpenseSyncStatus.cached))
              TextButton(onPressed: onRetry, child: const Text('Atualizar')),
          ],
        ),
      ),
    );
  }
}
