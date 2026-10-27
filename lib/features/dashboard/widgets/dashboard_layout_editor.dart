import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/features/dashboard/repository/dashboard_layout_repository.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';

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
  late final Map<String, DashboardCardSize> _sizes = Map.of(
    widget.initial.cardSizes,
  );
  late bool _integratedSummary = widget.initial.integratedSummary;

  static const _cardLabels = {
    'balance': 'Resumo do mês',
    'chart': 'Gastos mensais',
    'categories': 'Gastos por categoria',
    'accumulated': 'Evolução do mês',
    'periods': 'Gastos por período',
    'upcoming': 'Próximos sete dias',
    'daily': 'Gastos diários',
    'weekdays': 'Dias da semana',
    'quick_actions': 'Atalhos',
    'recent': 'Atividades recentes',
  };
  static const _descriptions = {
    'chart': 'Compare os últimos meses em barras.',
    'categories': 'Rosca com as cinco maiores e demais categorias.',
    'accumulated': 'Linha com o total acumulado de despesas até hoje.',
    'periods': 'Compare os gastos dos dias 1–7, 8–14 e seguintes.',
    'upcoming': 'Veja as despesas já cadastradas para os próximos dias.',
    'daily': 'Identifique os dias com maior gasto neste mês.',
    'weekdays': 'Compare os totais de segunda a domingo neste mês.',
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
      ...DashboardLayout.availableCardIds.where(
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
              integratedSummary: _integratedSummary,
              cardSizes: Map.of(_sizes),
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
    String? hiddenId,
  }) {
    final displayIds = ids.where((id) => id != hiddenId).toList();
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
          itemCount: displayIds.length,
          onReorderItem: (oldIndex, newIndex) {
            if (_saving) return;
            setState(() {
              displayIds.insert(newIndex, displayIds.removeAt(oldIndex));
              ids
                ..clear()
                ..addAll(displayIds);
              if (hiddenId != null) ids.add(hiddenId);
            });
          },
          itemBuilder: (context, index) {
            final id = displayIds[index];
            return Column(
              key: ValueKey(id),
              children: [
                CheckboxListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  title: Text(labels[id] ?? id),
                  subtitle: id == mandatoryId
                      ? const Text('Sempre disponível')
                      : _descriptions[id] == null
                      ? null
                      : Text(_descriptions[id]!),
                  value: visible.contains(id),
                  onChanged: _saving || id == mandatoryId
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
                ),
                if (visible.contains(id) &&
                    DashboardLayout.resizableCardIds.contains(id))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Text('Tamanho'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButton<DashboardCardSize>(
                            key: ValueKey('size_$id'),
                            isExpanded: true,
                            value: _sizes[id] ?? DashboardCardSize.regular,
                            items: [
                              for (final size in DashboardCardSize.values)
                                DropdownMenuItem(
                                  value: size,
                                  child: Text(
                                    size.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _saving
                                ? null
                                : (size) {
                                    if (size != null) {
                                      setState(() => _sizes[id] = size);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliersEnabled =
        ref.watch(authViewModelProvider).currentUser?.enableSuppliers ?? false;
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
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Escolha o que aparece e arraste para organizar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      title: const Text('Resumo integrado ao topo'),
                      subtitle: const Text(
                        'Desative para usar um cartão na ordem escolhida abaixo.',
                      ),
                      value: _integratedSummary,
                      onChanged: _saving
                          ? null
                          : (value) =>
                                setState(() => _integratedSummary = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _section(
                      title: 'Seções do painel',
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
                      hiddenId: suppliersEnabled ? null : 'suppliers',
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
