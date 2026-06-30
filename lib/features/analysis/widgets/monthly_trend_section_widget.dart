import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/services/snackbar_service.dart';

import '../viewmodel/analysis_viewmodel.dart';
import 'empty_chart_state_widget.dart';

class MonthlyTrendSectionWidget extends ConsumerWidget {
  const MonthlyTrendSectionWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(analysisViewModelProvider);
    final data = viewModel.lastNMonthsData;
    final chartEntries = data.entries.toList();

    if (chartEntries.isEmpty || chartEntries.every((e) => e.value == 0)) {
      return const EmptyChartStateWidget(
          message: 'Nenhum dado para exibir no gráfico',
          icon: Icons.show_chart);
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
            'Acompanhe sua evolução ao longo do tempo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPeriodSelector(context, viewModel),
          const SizedBox(height: AppSpacing.lg),
          _buildLineChart(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(
      BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);

    return Column(
      children: [
        if (!viewModel.useCustomRange) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: viewModel.availableMonthsCounts.map((count) {
              final isSelected = viewModel.selectedMonthsCount == count;
              return Expanded(
                child: GestureDetector(
                  onTap: () => viewModel.setSelectedMonthsCount(count),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                    ),
                    child: Text(
                      '${count}M',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            if (!viewModel.useCustomRange) ...[
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: viewModel.canGoToPreviousPeriod
                    ? () => viewModel.changePeriod(1)
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Material(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _showCustomRangePicker(context, viewModel),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            viewModel.currentPeriodLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!viewModel.useCustomRange) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: viewModel.canGoToNextPeriod
                    ? () => viewModel.changePeriod(-1)
                    : null,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ],
        ),
        if (viewModel.useCustomRange) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => viewModel.clearCustomRange(),
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Voltar ao padrão'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  void _showCustomRangePicker(
      BuildContext context, AnalysisViewModel viewModel) {
    final availableRange = viewModel.availableDateRange;
    if (availableRange == null) {
      SnackbarService.showError(context, 'Nenhum dado disponível para seleção');
      return;
    }

    showDateRangePicker(
      context: context,
      firstDate: availableRange.start,
      lastDate: availableRange.end,
      initialDateRange: viewModel.useCustomRange
          ? DateTimeRange(
              start: viewModel.customStartDate ?? availableRange.start,
              end: viewModel.customEndDate ?? availableRange.end,
            )
          : null,
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecionar período',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      fieldStartLabelText: 'Data início',
      fieldEndLabelText: 'Data fim',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    ).then((range) {
      if (range != null) {
        final startDate = DateTime(range.start.year, range.start.month, 1);
        final endDate = DateTime(range.end.year, range.end.month + 1, 0);
        viewModel.setCustomDateRange(startDate, endDate);
      }
    });
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
          message: 'Nenhum dado para exibir', icon: Icons.show_chart);
    }

    final spots = chartEntries
        .asMap()
        .entries
        .map((entry) => FlSpot(
              entry.key.toDouble(),
              entry.value.value,
            ))
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
                color: theme.dividerColor.withValues(alpha: 0.1), strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(
                color: theme.dividerColor.withValues(alpha: 0.1), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  final date =
                      DateFormat('yyyy-MM').parse(chartEntries[index].key);
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
                  return Text('${inK.toStringAsFixed(1).replaceAll('.0', '')}k',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                      textAlign: TextAlign.left);
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
}
