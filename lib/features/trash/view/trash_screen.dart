import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_feedback_panel.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:key_budget/features/trash/repository/trash_repository.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  String _typeName(String collection) => switch (collection) {
    'expenses' => 'Lançamento',
    'credentials' => 'Credencial',
    'documents' => 'Documento',
    'suppliers' => 'Fornecedor',
    _ => 'Item',
  };

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    String userId,
    TrashEntry entry,
  ) async {
    try {
      await ref.read(trashRepositoryProvider).restore(userId, entry.id);
      if (context.mounted) {
        SnackbarService.showSuccess(
          context,
          '${_typeName(entry.collection)} restaurado.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        SnackbarService.showError(
          context,
          'Não foi possível restaurar. Verifique se já existe um item com o mesmo ID.',
        );
      }
    }
  }

  Future<void> _deleteForever(
    BuildContext context,
    WidgetRef ref,
    String userId,
    TrashEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir definitivamente?'),
        content: Text('“${entry.title}” não poderá ser restaurado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
      animationStyle: AppAnimations.routeStyle(context),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(trashRepositoryProvider).deleteForever(userId, entry.id);
      if (entry.collection == 'documents') {
        await ref
            .read(documentViewModelProvider)
            .retryPendingAttachmentCleanup(userId);
      }
      if (context.mounted) {
        SnackbarService.showSuccess(context, 'Item excluído definitivamente.');
      }
    } catch (_) {
      if (context.mounted) {
        SnackbarService.showError(context, 'Não foi possível excluir o item.');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authViewModelProvider).currentUser?.id;
    final entries = userId == null
        ? null
        : ref.watch(trashEntriesProvider(userId));
    return AppPageScaffold(
      appBar: AppBar(title: const Text('Lixeira')),
      body: userId == null
          ? const AppFeedbackPanel(
              title: 'Entre na sua conta',
              message: 'Faça login para acessar a lixeira.',
            )
          : entries!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => AppFeedbackPanel(
                title: 'Não foi possível carregar a lixeira',
                message: 'Confira a conexão e tente novamente.',
                type: AppFeedbackType.error,
                actionLabel: 'Tentar novamente',
                onAction: () => ref.invalidate(trashEntriesProvider(userId)),
              ),
              data: (items) => items.isEmpty
                  ? const AppFeedbackPanel(
                      title: 'Lixeira vazia',
                      message: 'Itens excluídos ficam disponíveis por 30 dias.',
                    )
                  : ResponsiveCenter(
                      maxWidth: 760,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final entry = items[index];
                          return AppCard(
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              title: Text(entry.title),
                              subtitle: Text(
                                '${_typeName(entry.collection)} · disponível até ${DateFormat('dd/MM/yyyy').format(entry.expiresAt)}',
                              ),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'Ações de ${entry.title}',
                                onSelected: (action) {
                                  if (action == 'restore') {
                                    _restore(context, ref, userId, entry);
                                  } else {
                                    _deleteForever(context, ref, userId, entry);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'restore',
                                    child: Text('Restaurar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Excluir definitivamente'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
    );
  }
}
