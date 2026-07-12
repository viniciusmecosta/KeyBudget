import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

import '../viewmodel/analysis_viewmodel.dart';
import 'empty_chart_state_widget.dart';

class MonthlyTrendSectionWidget extends ConsumerWidget {
  const MonthlyTrendSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(analysisViewModelProvider);
    final enableIncomes =
        ref.watch(authViewModelProvider).currentUser?.enableIncomes ?? false;

    if (enableIncomes) {
      return _buildIncomesLayout(context, viewModel);
    }

    final data = viewModel.lastNMonthsData;
    final chartEntries = data.entries.toList();

    if (chartEntries.isEmpty || chartEntries.every((e) => e.value == 0)) {
      return const EmptyChartStateWidget(
        message: 'Nenhum dado para exibir no gráfico',
        icon: Icons.show_chart,
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico Mensal',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Evolução ao longo do tempo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: viewModel.trendMonthsCount,
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('Últimos 3 meses')),
                    DropdownMenuItem(value: 6, child: Text('Últimos 6 meses')),
                    DropdownMenuItem(
                      value: 12,
                      child: Text('Últimos 12 meses'),
                    ),
                    DropdownMenuItem(value: 24, child: Text('Últimos 2 anos')),
                  ],
                  onChanged: (value) {
                    if (value != null) viewModel.setTrendMonthsCount(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildLineChart(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildIncomesLayout(
    BuildContext context,
    AnalysisViewModel viewModel,
  ) {
    final data = viewModel.lastNMonthsTrendData;
    final chartEntries = data.entries.toList();

    if (chartEntries.isEmpty ||
        chartEntries.every(
          (e) => e.value.incomes == 0 && e.value.expenses == 0,
        )) {
      return const EmptyChartStateWidget(
        message: 'Nenhum dado para exibir no gráfico',
        icon: Icons.show_chart,
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tendência Histórica',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Entradas vs Saídas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: viewModel.trendMonthsCount,
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('Últimos 3 meses')),
                    DropdownMenuItem(value: 6, child: Text('Últimos 6 meses')),
                    DropdownMenuItem(
                      value: 12,
                      child: Text('Últimos 12 meses'),
                    ),
                    DropdownMenuItem(value: 24, child: Text('Últimos 2 anos')),
                  ],
                  onChanged: (value) {
                    if (value != null) viewModel.setTrendMonthsCount(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildDualLineChart(context, viewModel, chartEntries),
        ],
      ),
    );
  }

  double _getRoundedMaxValue(double maxValue) {
    if (maxValue <= 0) return 500;
    const step = 500.0;
    double rounded = (maxValue / step).ceil() * step;
    return rounded == maxValue ? rounded + step : rounded;
  }

  Widget _buildLineChart(BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);
    final data = viewModel.lastNMonthsData;
    final chartEntries = data.entries.toList();

    if (chartEntries.isEmpty || chartEntries.every((e) => e.value == 0)) {
      return const EmptyChartStateWidget(
        message: 'Nenhum dado para exibir',
        icon: Icons.show_chart,
      );
    }

    final spots = chartEntries
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();
    final maxValue = spots.map((spot) => spot.y).reduce(max);
    final roundedMaxValue = _getRoundedMaxValue(maxValue);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 500,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: theme.dividerColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= chartEntries.length) {
                    return const SizedBox.shrink();
                  }
                  final date = DateFormat(
                    'yyyy-MM',
                  ).parse(chartEntries[index].key);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MMM', 'pt_BR').format(date).substring(0, 3),
                      style: theme.textTheme.bodySmall!.copyWith(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 500,
                getTitlesWidget: (value, meta) {
                  final inK = value / 1000;
                  return Text(
                    '${inK.toStringAsFixed(1).replaceAll('.0', '')}k',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                    textAlign: TextAlign.left,
                  );
                },
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (chartEntries.length - 1).toDouble(),
          minY: 0,
          maxY: roundedMaxValue,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final monthKey = chartEntries[index].key;
                  final date = DateFormat('yyyy-MM').parse(monthKey);
                  return LineTooltipItem(
                    '${DateFormat.yMMM('pt_BR').format(date)}\n${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(spot.y)}',
                    TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompactCurrency(double value) {
    if (value >= 1000000) {
      return "${(value / 1000000).toStringAsFixed(1)}M";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}k";
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildDualLineChart(
    BuildContext context,
    AnalysisViewModel viewModel,
    List<MapEntry<String, ({double incomes, double expenses})>> chartEntries,
  ) {
    final theme = Theme.of(context);

    final incomesSpots = chartEntries
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value.incomes))
        .toList();

    final expensesSpots = chartEntries
        .asMap()
        .entries
        .map(
          (entry) => FlSpot(entry.key.toDouble(), entry.value.value.expenses),
        )
        .toList();

    double maxValue = 0;
    for (var e in chartEntries) {
      if (e.value.incomes > maxValue) maxValue = e.value.incomes;
      if (e.value.expenses > maxValue) maxValue = e.value.expenses;
    }
    maxValue = _getRoundedMaxValue(maxValue);

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (chartEntries.length - 1).toDouble(),
          minY: 0,
          maxY: maxValue,
          clipData: const FlClipData.all(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final textStyle = TextStyle(
                    color: touchedSpot.bar.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  );
                  final currencyFormatter = NumberFormat.currency(
                    locale: 'pt_BR',
                    symbol: 'R\$',
                  );
                  return LineTooltipItem(
                    currencyFormatter.format(touchedSpot.y),
                    textStyle,
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 4 > 0 ? maxValue / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.colorScheme.outlineVariant.withAlpha(50),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxValue / 4 > 0 ? maxValue / 4 : 1,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == maxValue || value == 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      _formatCompactCurrency(value),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= chartEntries.length) {
                    return const SizedBox.shrink();
                  }

                  final dateStr = chartEntries[index].key;
                  final date = DateTime.parse('$dateStr-01');
                  final monthStr = DateFormat('MMM', 'pt_BR').format(date);

                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      monthStr.toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: incomesSpots,
              isCurved: true,
              color: Colors.greenAccent[400]!,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: Colors.greenAccent[400]!,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.greenAccent[400]!.withAlpha(30),
              ),
            ),
            LineChartBarData(
              spots: expensesSpots,
              isCurved: true,
              color: theme.colorScheme.error,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                      radius: 3,
                      color: theme.colorScheme.error,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.surface,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.error.withAlpha(30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
