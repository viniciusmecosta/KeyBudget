import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

/// Uses the dashboard's existing data, without another database subscription.
class DashboardCategorySummary extends ConsumerStatefulWidget {
  const DashboardCategorySummary({super.key});

  @override
  ConsumerState<DashboardCategorySummary> createState() =>
      _DashboardCategorySummaryState();
}

class _DashboardCategorySummaryState
    extends ConsumerState<DashboardCategorySummary> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(dashboardViewModelProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final totals = <String?, int>{};
    for (final expense in model.allExpenses) {
      if (expense.isIncome == true ||
          expense.date.year != now.year ||
          expense.date.month != now.month ||
          !expense.date.isBefore(tomorrow)) {
        continue;
      }
      totals.update(
        expense.categoryId,
        (value) => value + expense.money.amountMinor,
        ifAbsent: () => expense.money.amountMinor,
      );
    }
    final ordered = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final visible = ordered.where((entry) => entry.value > 0).toList();
    final slices = visible.take(5).toList();
    final hasRemainder = visible.length > 5;
    if (visible.length > 5) {
      slices.add(
        MapEntry(
          null,
          visible.skip(5).fold<int>(0, (sum, entry) => sum + entry.value),
        ),
      );
    }
    final total = visible.fold<int>(0, (sum, entry) => sum + entry.value);
    final colors = [
      theme.colorScheme.primary,
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFF472B6),
      theme.colorScheme.outline,
    ];
    String name(int index) => hasRemainder && index == slices.length - 1
        ? 'Demais categorias'
        : model.categoryViewModel.getCategoryById(slices[index].key)?.name ??
              'Sem categoria';
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gastos por categoria', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Realizados neste mês', style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          if (total == 0)
            const Text(
              'Suas categorias aparecerão aqui quando você registrar uma despesa.',
            ),
          if (total > 0) ...[
            Semantics(
              label:
                  'Distribuição dos gastos por categoria. As cinco maiores e as demais agrupadas em Demais categorias.',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 148,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          if (event is! FlTapUpEvent) return;
                          final index =
                              response?.touchedSection?.touchedSectionIndex;
                          setState(
                            () => _selected =
                                index != null &&
                                    index >= 0 &&
                                    index < slices.length
                                ? index
                                : null,
                          );
                        },
                      ),
                      centerSpaceRadius: 40,
                      sectionsSpace: 3,
                      sections: [
                        for (var index = 0; index < slices.length; index++)
                          PieChartSectionData(
                            value: slices[index].value.toDouble(),
                            color: colors[index],
                            radius: _selected == index ? 34 : 26,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_selected != null && _selected! < slices.length)
              Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${name(_selected!)} · ${currency.format(slices[_selected!].value / 100)}',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (context) => SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Gastos por categoria',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          for (var index = 0; index < slices.length; index++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                '${name(index)}: ${currency.format(slices[index].value / 100)}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Ver valores'),
            ),
            for (var index = 0; index < slices.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors[index],
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(width: 10, height: 10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name(index),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${(slices[index].value * 100 / total).toStringAsFixed(1).replaceAll('.', ',')}%',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
