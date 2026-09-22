import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_feedback_panel.dart';

enum ViewStateKind {
  initialLoading,
  updatingWithData,
  emptyAccount,
  emptyFilter,
  errorNoData,
  errorWithData,
  offline,
  conflict,
  ready
}

class StateView extends StatelessWidget {
  final ViewStateKind state;
  final Widget? content;
  final String? emptyTitle;
  final String? emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? loadingSkeleton;

  const StateView({
    super.key,
    required this.state,
    this.content,
    this.emptyTitle,
    this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.errorMessage,
    this.onRetry,
    this.loadingSkeleton,
  });

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case ViewStateKind.initialLoading:
        return loadingSkeleton ??
            Center(
              child: Semantics(
                label: 'Carregando informações',
                child: const CircularProgressIndicator(),
              ),
            );

      case ViewStateKind.updatingWithData:
        return Stack(
          children: [
            ?content,
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
          ],
        );

      case ViewStateKind.emptyAccount:
        return AppFeedbackPanel(
          title: emptyTitle ?? 'Nenhum registro encontrado',
          message: emptyMessage ?? 'Comece adicionando seu primeiro item.',
          type: AppFeedbackType.empty,
          actionLabel: emptyActionLabel ?? 'Adicionar',
          onAction: onEmptyAction,
        );

      case ViewStateKind.emptyFilter:
        return AppFeedbackPanel(
          title: emptyTitle ?? 'Nenhum resultado para os filtros',
          message: emptyMessage ?? 'Tente ajustar os filtros selecionados.',
          type: AppFeedbackType.empty,
          icon: Icons.filter_alt_off_rounded,
          actionLabel: emptyActionLabel ?? 'Limpar filtros',
          onAction: onEmptyAction,
        );

      case ViewStateKind.errorNoData:
        return AppFeedbackPanel(
          title: 'Não foi possível carregar os dados',
          message: errorMessage ?? 'Ocorreu um erro ao buscar as informações.',
          type: AppFeedbackType.error,
          actionLabel: 'Tentar novamente',
          onAction: onRetry,
        );

      case ViewStateKind.errorWithData:
        final theme = Theme.of(context);
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              color: theme.colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Dados desatualizados. Toque para recarregar.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (onRetry != null)
                    TextButton(
                      onPressed: onRetry,
                      child: Text(
                        'Recarregar',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (content != null) Expanded(child: content!),
          ],
        );

      case ViewStateKind.offline:
        return AppFeedbackPanel(
          title: 'Sem conexão com a internet',
          message: 'Verifique sua conexão e tente novamente.',
          type: AppFeedbackType.warning,
          icon: Icons.wifi_off_rounded,
          actionLabel: 'Tentar novamente',
          onAction: onRetry,
        );

      case ViewStateKind.conflict:
        return AppFeedbackPanel(
          title: 'Conflito de dados detectado',
          message: errorMessage ?? 'As informações foram alteradas em outro dispositivo.',
          type: AppFeedbackType.warning,
          icon: Icons.sync_problem_rounded,
          actionLabel: 'Atualizar dados',
          onAction: onRetry,
        );

      case ViewStateKind.ready:
        return content ?? const SizedBox.shrink();
    }
  }
}
