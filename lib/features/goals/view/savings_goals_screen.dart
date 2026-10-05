import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/design_system/widgets/app_feedback_panel.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/money/money_parser.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/goals/model/savings_goal.dart';
import 'package:key_budget/features/goals/repository/savings_goal_repository.dart';

class SavingsGoalsScreen extends ConsumerStatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  ConsumerState<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends ConsumerState<SavingsGoalsScreen> {
  bool _showArchived = false;

  Future<void> _editGoal(String userId, [SavingsGoal? goal]) async {
    final nameController = TextEditingController(text: goal?.name ?? '');
    final targetController = TextEditingController(
      text: goal == null
          ? ''
          : Money.fromCents(goal.targetMinor).formatBrl(includeSymbol: false),
    );
    var deadline = goal?.deadline;
    String? error;
    final result =
        await showDialog<({String name, int targetMinor, DateTime? deadline})>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) => AlertDialog(
              title: Text(goal == null ? 'Nova meta' : 'Editar meta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nome da meta',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Valor desejado',
                        prefixText: 'R\$ ',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        deadline == null
                            ? 'Sem prazo'
                            : 'Prazo: ${DateFormat('dd/MM/yyyy').format(deadline!)}',
                      ),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate: deadline ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null) {
                          setDialogState(() => deadline = selected);
                        }
                      },
                    ),
                    if (deadline != null)
                      TextButton(
                        onPressed: () => setDialogState(() => deadline = null),
                        child: const Text('Remover prazo'),
                      ),
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(dialogContext).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    try {
                      final target = MoneyParser.parse(
                        targetController.text,
                      ).amountMinor;
                      if (nameController.text.trim().isEmpty || target <= 0) {
                        throw const FormatException();
                      }
                      Navigator.of(dialogContext).pop((
                        name: nameController.text.trim(),
                        targetMinor: target,
                        deadline: deadline,
                      ));
                    } catch (_) {
                      setDialogState(
                        () => error = 'Informe nome e valor maiores que zero.',
                      );
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ),
        );
    nameController.dispose();
    targetController.dispose();
    if (result == null || !mounted) return;
    try {
      final repository = ref.read(savingsGoalRepositoryProvider);
      if (goal == null) {
        await repository.createGoal(
          userId,
          name: result.name,
          targetMinor: result.targetMinor,
          deadline: result.deadline,
        );
      } else {
        await repository.updateGoal(
          userId,
          goal.id,
          name: result.name,
          targetMinor: result.targetMinor,
          deadline: result.deadline,
        );
      }
      if (mounted) {
        SnackbarService.showSuccess(context, 'Meta salva.');
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Não foi possível salvar a meta. Tente novamente.',
        );
      }
    }
  }

  Future<void> _moveAmount(
    String userId,
    SavingsGoal goal,
    bool withdrawal,
  ) async {
    final controller = TextEditingController();
    String? error;
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(withdrawal ? 'Retirar da meta' : 'Adicionar à meta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                ),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final value = MoneyParser.parse(controller.text).amountMinor;
                  if (value <= 0 || (withdrawal && value > goal.savedMinor)) {
                    throw const FormatException();
                  }
                  Navigator.of(dialogContext).pop(withdrawal ? -value : value);
                } catch (_) {
                  setDialogState(
                    () => error = withdrawal
                        ? 'Informe um valor entre R\$ 0,01 e o saldo da meta.'
                        : 'Informe um valor maior que zero.',
                  );
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (amount == null || !mounted) return;
    try {
      await ref
          .read(savingsGoalRepositoryProvider)
          .moveAmount(userId, goal.id, amount);
      if (mounted) {
        SnackbarService.showSuccess(context, 'Valor da meta atualizado.');
      }
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Não foi possível atualizar a meta. Tente novamente.',
        );
      }
    }
  }

  void _showHistory(String userId, SavingsGoal goal) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.55,
          child: Consumer(
            builder: (context, ref, _) {
              final movements = ref.watch(
                goalMovementsProvider((userId: userId, goalId: goal.id)),
              );
              return Column(
                children: [
                  Text(
                    'Histórico de ${goal.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Expanded(
                    child: movements.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => const Center(
                        child: Text('Não foi possível carregar o histórico.'),
                      ),
                      data: (items) => items.isEmpty
                          ? const Center(
                              child: Text('Nenhuma movimentação ainda.'),
                            )
                          : ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return ListTile(
                                  leading: Icon(
                                    item.amountMinor > 0
                                        ? Icons.add_circle_outline
                                        : Icons.remove_circle_outline,
                                  ),
                                  title: Text(
                                    Money.fromCents(
                                      item.amountMinor.abs(),
                                    ).formatBrl(),
                                  ),
                                  subtitle: Text(
                                    DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(item.createdAt),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _goalCard(String userId, SavingsGoal goal) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(goal.name, style: theme.textTheme.titleMedium),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções da meta ${goal.name}',
                onSelected: (value) async {
                  if (value == 'edit') {
                    await _editGoal(userId, goal);
                  } else if (value == 'history') {
                    _showHistory(userId, goal);
                  } else {
                    try {
                      await ref
                          .read(savingsGoalRepositoryProvider)
                          .setArchived(userId, goal.id, value == 'archive');
                    } catch (_) {
                      if (mounted) {
                        SnackbarService.showError(
                          context,
                          'Não foi possível atualizar a meta.',
                        );
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  if (!goal.isArchived)
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(
                    value: 'history',
                    child: Text('Histórico'),
                  ),
                  PopupMenuItem(
                    value: goal.isArchived ? 'restore' : 'archive',
                    child: Text(goal.isArchived ? 'Reativar' : 'Arquivar'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${Money.fromCents(goal.savedMinor).formatBrl()} de ${Money.fromCents(goal.targetMinor).formatBrl()}',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label:
                '${(goal.progress * 100).round()} por cento da meta ${goal.name}',
            child: LinearProgressIndicator(
              value: goal.progress.clamp(0.0, 1.0),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            goal.isComplete
                ? 'Meta alcançada'
                : '${Money.fromCents(goal.remainingMinor).formatBrl()} restantes',
            style: theme.textTheme.bodySmall,
          ),
          if (goal.deadline != null)
            Text(
              'Prazo: ${DateFormat('dd/MM/yyyy').format(goal.deadline!)}',
              style: theme.textTheme.bodySmall,
            ),
          if (!goal.isArchived) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton.icon(
                  onPressed: () => _moveAmount(userId, goal, false),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                ),
                if (goal.savedMinor > 0)
                  TextButton.icon(
                    onPressed: () => _moveAmount(userId, goal, true),
                    icon: const Icon(Icons.remove),
                    label: const Text('Retirar'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authViewModelProvider).currentUser?.id;
    final goals = userId == null
        ? null
        : ref.watch(savingsGoalsProvider(userId));
    final visible =
        goals?.value
            ?.where((goal) => goal.isArchived == _showArchived)
            .toList() ??
        [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        actions: [
          IconButton(
            tooltip: _showArchived
                ? 'Ver metas ativas'
                : 'Ver metas arquivadas',
            onPressed: () => setState(() => _showArchived = !_showArchived),
            icon: Icon(
              _showArchived ? Icons.flag_outlined : Icons.archive_outlined,
            ),
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Entre na sua conta para ver as metas.'))
          : goals!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => AppFeedbackPanel(
                title: 'Não foi possível carregar as metas',
                message: 'Confira sua conexão e tente novamente.',
                type: AppFeedbackType.error,
                actionLabel: 'Tentar novamente',
                onAction: () => ref.invalidate(savingsGoalsProvider(userId)),
              ),
              data: (_) => visible.isEmpty
                  ? Center(
                      child: Text(
                        _showArchived
                            ? 'Nenhuma meta arquivada.'
                            : 'Crie uma meta para acompanhar seu progresso.',
                      ),
                    )
                  : ResponsiveCenter(
                      maxWidth: 960,
                      child: LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Wrap(
                                spacing: AppSpacing.md,
                                runSpacing: AppSpacing.md,
                                children: visible
                                    .map(
                                      (goal) => SizedBox(
                                        width: constraints.maxWidth >= 700
                                            ? (constraints.maxWidth -
                                                      AppSpacing.md * 3) /
                                                  2
                                            : constraints.maxWidth -
                                                  AppSpacing.md * 2,
                                        child: _goalCard(userId, goal),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                      ),
                    ),
            ),
      floatingActionButton: userId == null || _showArchived
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _editGoal(userId),
              icon: const Icon(Icons.add),
              label: const Text('Nova meta'),
            ),
    );
  }
}
