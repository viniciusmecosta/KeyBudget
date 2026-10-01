import 'dart:async';

import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class ExpenseSyncIndicator extends StatefulWidget {
  final ExpenseSyncStatus status;
  final VoidCallback? onRetry;

  const ExpenseSyncIndicator({super.key, required this.status, this.onRetry});

  @override
  State<ExpenseSyncIndicator> createState() => _ExpenseSyncIndicatorState();
}

class _ExpenseSyncIndicatorState extends State<ExpenseSyncIndicator> {
  Timer? _cacheDelay;
  bool _showCache = false;

  @override
  void initState() {
    super.initState();
    _updateCacheVisibility();
  }

  @override
  void didUpdateWidget(covariant ExpenseSyncIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _updateCacheVisibility();
  }

  void _updateCacheVisibility() {
    _cacheDelay?.cancel();
    _showCache = false;
    if (widget.status == ExpenseSyncStatus.cached) {
      _cacheDelay = Timer(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showCache = true);
      });
    }
  }

  @override
  void dispose() {
    _cacheDelay?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    if (status == ExpenseSyncStatus.loading ||
        status == ExpenseSyncStatus.synced ||
        (status == ExpenseSyncStatus.cached && !_showCache)) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final canRetry =
        widget.onRetry != null &&
        (status == ExpenseSyncStatus.failed ||
            status == ExpenseSyncStatus.cached);
    final (icon, label, message, color) = switch (status) {
      ExpenseSyncStatus.cached => (
        Icons.cloud_off_outlined,
        'Em cache',
        'Dados em cache. Aguardando conexão.',
        theme.colorScheme.onSurfaceVariant,
      ),
      ExpenseSyncStatus.pending => (
        Icons.cloud_upload_outlined,
        'Pendente',
        'Alterações aguardando confirmação.',
        theme.colorScheme.tertiary,
      ),
      ExpenseSyncStatus.failed => (
        Icons.sync_problem_rounded,
        'Falha',
        'Falha ao sincronizar os lançamentos.',
        theme.colorScheme.error,
      ),
      ExpenseSyncStatus.synced ||
      ExpenseSyncStatus.loading => throw StateError('Estado não visível.'),
    };

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: message,
                child: Semantics(
                  label: message,
                  liveRegion: true,
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.sm,
                        right: canRetry ? 0 : AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 15),
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (canRetry)
                IconButton(
                  tooltip: 'Tentar sincronizar novamente',
                  onPressed: widget.onRetry,
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  icon: Icon(Icons.refresh_rounded, color: color, size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
