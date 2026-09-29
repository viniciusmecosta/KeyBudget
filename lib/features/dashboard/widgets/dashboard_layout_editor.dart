import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/dashboard/repository/dashboard_layout_repository.dart';

class DashboardLayoutEditor extends ConsumerStatefulWidget {
  final String userId;
  final DashboardLayout initial;

  const DashboardLayoutEditor({
    super.key,
    required this.userId,
    required this.initial,
  });

  @override
  ConsumerState<DashboardLayoutEditor> createState() =>
      _DashboardLayoutEditorState();
}

class _DashboardLayoutEditorState extends ConsumerState<DashboardLayoutEditor> {
  late List<String> _cards;
  late List<String> _actions;
  bool _saving = false;

  static const _cardLabels = {
    'balance': 'Resumo do mês',
    'chart': 'Gastos mensais',
    'quick_actions': 'Atalhos',
    'recent': 'Atividades recentes',
  };
  static const _actionLabels = {
    'expense': 'Nova despesa',
    'credentials': 'Cofre',
    'analysis': 'Análise',
    'suppliers': 'Fornecedores',
  };

  @override
  void initState() {
    super.initState();
    _cards = [
      ...widget.initial.cards,
      ...DashboardLayout.cardIds.where(
        (id) => !widget.initial.cards.contains(id),
      ),
    ];
    _actions = [
      ...widget.initial.actions,
      ...DashboardLayout.actionIds.where(
        (id) => !widget.initial.actions.contains(id),
      ),
    ];
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(dashboardLayoutRepositoryProvider)
          .save(
            widget.userId,
            DashboardLayout(
              cards: _cards.where((id) => _visibleCards.contains(id)).toList(),
              actions: _actions
                  .where((id) => _visibleActions.contains(id))
                  .toList(),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar o painel. Tente novamente.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  late final Set<String> _visibleCards = widget.initial.cards.toSet();
  late final Set<String> _visibleActions = widget.initial.actions.toSet();

  Widget _section({
    required String title,
    required List<String> ids,
    required Map<String, String> labels,
    required Set<String> visible,
    String? mandatoryId,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: ids.length,
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              ids.insert(newIndex, ids.removeAt(oldIndex));
            });
          },
          itemBuilder: (context, index) {
            final id = ids[index];
            return CheckboxListTile(
              key: ValueKey(id),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              title: Text(labels[id] ?? id),
              subtitle: id == mandatoryId
                  ? const Text('Sempre disponível')
                  : null,
              value: visible.contains(id),
              onChanged: id == mandatoryId
                  ? null
                  : (enabled) => setState(() {
                      if (enabled == true) {
                        visible.add(id);
                      } else {
                        visible.remove(id);
                      }
                    }),
              secondary: ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle_rounded),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Personalizar painel',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _section(
                      title: 'Cartões',
                      ids: _cards,
                      labels: _cardLabels,
                      visible: _visibleCards,
                      mandatoryId: 'recent',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _section(
                      title: 'Atalhos',
                      ids: _actions,
                      labels: _actionLabels,
                      visible: _visibleActions,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Salvando…' : 'Salvar painel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
