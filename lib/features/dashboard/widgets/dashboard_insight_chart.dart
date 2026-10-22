import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/design_system/widgets/app_section_header.dart';
import 'package:key_budget/features/dashboard/domain/dashboard_insights.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

enum DashboardInsight { accumulated, periods, upcoming }

final dashboardInsightsProvider = Provider<DashboardInsights>(
  (ref) => DashboardInsights.fromExpenses(
    ref.watch(dashboardViewModelProvider).allExpenses,
    DateTime.now(),
  ),
);

class DashboardInsightChart extends ConsumerWidget {
  const DashboardInsightChart({super.key, required this.insight});
  final DashboardInsight insight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardInsightsProvider);
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final line = insight == DashboardInsight.accumulated;
    final values = switch (insight) {
      DashboardInsight.accumulated => data.accumulated,
      DashboardInsight.periods => data.monthPeriods,
      DashboardInsight.upcoming => data.upcoming,
    };
    final title = switch (insight) {
      DashboardInsight.accumulated => 'Evolução do mês',
      DashboardInsight.periods => 'Gastos por período',
      DashboardInsight.upcoming => 'Próximos sete dias',
    };
    final subtitle = switch (insight) {
      DashboardInsight.accumulated => 'Despesas acumuladas até hoje',
      DashboardInsight.periods => 'Dias 1–7, 8–14… • período atual parcial',
      DashboardInsight.upcoming => 'Despesas cadastradas para datas futuras',
    };
    String label(int i) => switch (insight) {
      DashboardInsight.accumulated => i == 0 ? 'Início' : 'Dia $i',
      DashboardInsight.periods =>
        '${i * 7 + 1}–${math.min((i + 1) * 7, data.today.day)}',
      DashboardInsight.upcoming => DateFormat('dd/MM').format(
        DateTime(data.today.year, data.today.month, data.today.day + i + 1),
      ),
    };
    final total = line
        ? values.last
        : values.fold<int>(0, (sum, value) => sum + value);
    final maximum = math.max(1, values.reduce(math.max)).toDouble() * 1.15;
    final titles = FlTitlesData(
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: MediaQuery.textScalerOf(context).scale(12) + 16,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (value != i ||
                i < 0 ||
                i >= values.length ||
                (line &&
                    i != 0 &&
                    i != values.length - 1 &&
                    i != (values.length - 1) ~/ 2) ||
                (insight == DashboardInsight.upcoming && i.isOdd) ||
                (MediaQuery.textScalerOf(context).scale(12) > 16 &&
                    i != 0 &&
                    i != values.length - 1)) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(label(i), style: theme.textTheme.labelSmall),
            );
          },
        ),
      ),
    );
    void showValues() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .6,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(subtitle),
              for (var i = line ? 1 : 0; i < values.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(label(i)),
                  subtitle: Text(currency.format(values[i] / 100)),
                ),
            ],
          ),
        ),
      ),
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: title,
            subtitle: subtitle,
            keepActionInline: true,
            action: AppSectionAction(
              label: 'Ver valores de $title',
              icon: Icons.open_in_full_rounded,
              onPressed: showValues,
            ),
          ),
          const SizedBox(height: 8),
          Text(currency.format(total / 100), style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (values.every((value) => value == 0))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                insight == DashboardInsight.upcoming
                    ? 'Nenhuma despesa cadastrada para os próximos sete dias.'
                    : 'Seus gastos aparecerão aqui quando houver lançamentos neste mês.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            Semantics(
              label:
                  '$title. Total ${currency.format(total / 100)}. Use Ver valores para consultar os detalhes.',
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 144,
                  child: line
                      ? LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: (values.length - 1).toDouble(),
                            minY: 0,
                            maxY: maximum,
                            titlesData: titles,
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (spots) => spots
                                    .map(
                                      (spot) => LineTooltipItem(
                                        '${label(spot.x.toInt())}\n${currency.format(spot.y / 100)}',
                                        TextStyle(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                getTooltipColor: (_) =>
                                    theme.colorScheme.surface,
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (var i = 0; i < values.length; i++)
                                    FlSpot(i.toDouble(), values[i].toDouble()),
                                ],
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                isCurved: false,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: .08,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          duration: AppAnimations.durationFor(
                            context,
                            AppAnimations.transition,
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            minY: 0,
                            maxY: maximum,
                            titlesData: titles,
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) =>
                                    theme.colorScheme.surface,
                                getTooltipItem: (group, _, rod, _) =>
                                    BarTooltipItem(
                                      '${label(group.x)}\n${currency.format(rod.toY / 100)}',
                                      TextStyle(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              ),
                            ),
                            barGroups: [
                              for (var i = 0; i < values.length; i++)
                                BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: values[i].toDouble(),
                                      color: theme.colorScheme.primary,
                                      width: 18,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          duration: AppAnimations.durationFor(
                            context,
                            AppAnimations.transition,
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
