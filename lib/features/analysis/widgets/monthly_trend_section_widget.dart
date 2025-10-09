import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:provider/provider.dart';

import '../viewmodel/analysis_viewmodel.dart';
import 'empty_chart_state_widget.dart';

class MonthlyTrendSectionWidget extends StatelessWidget {
  const MonthlyTrendSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AnalysisViewModel>(context);
    final data = viewModel.lastNMonthsData;
    final chartEntries = data.entries.toList();

    if (chartEntries.isEmpty || chartEntries.every((e) => e.value == 0)) {
      return const EmptyChartStateWidget(
          message: 'Nenhum dado para exibir no gráfico',
          icon: Icons.show_chart);
    }
    return Column(
      children: [
        _buildPeriodSelector(context, viewModel),
        const SizedBox(height: AppTheme.spaceM),
        _buildLineChart(context, viewModel),
      ],
    );
  }

  Widget _buildPeriodSelector(
      BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
        ),
      ),
      child: Column(
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: theme.colorScheme.outline
                                    .withAlpha((255 * 0.2).round()),
                              ),
                      ),
                      child: Text(
                        '${count}M',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spaceM),
          ],
          Row(
            children: [
              if (!viewModel.useCustomRange) ...[
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 24),
                  onPressed: viewModel.canGoToPreviousPeriod
                      ? () => viewModel.changePeriod(1)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary
                        .withAlpha((255 * 0.1).round()),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceS),
              ],
              Expanded(
                child: Material(
                  color: viewModel.useCustomRange
                      ? theme.colorScheme.secondary
                          .withAlpha((255 * 0.1).round())
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _showCustomRangePicker(context, viewModel),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: viewModel.useCustomRange
                              ? theme.colorScheme.secondary
                                  .withAlpha((255 * 0.3).round())
                              : theme.colorScheme.outline
                                  .withAlpha((255 * 0.2).round()),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.date_range,
                            size: 18,
                            color: viewModel.useCustomRange
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppTheme.spaceS),
                          Flexible(
                            child: Text(
                              viewModel.currentPeriodLabel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: viewModel.useCustomRange
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
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
                const SizedBox(width: AppTheme.spaceS),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 24),
                  onPressed: viewModel.canGoToNextPeriod
                      ? () => viewModel.changePeriod(-1)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary
                        .withAlpha((255 * 0.1).round()),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
          if (viewModel.useCustomRange) ...[
            const SizedBox(height: AppTheme.spaceM),
            TextButton.icon(
              onPressed: () => viewModel.clearCustomRange(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Voltar ao padrão'),
              style: TextButton.styleFrom(
                foregroundColor:
                    theme.colorScheme.onSurface.withAlpha((255 * 0.6).round()),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
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

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withAlpha((255 * 0.1).round()),
                      strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(
                      color: theme.dividerColor.withAlpha((255 * 0.1).round()),
                      strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
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
                        final date = DateFormat('yyyy-MM')
                            .parse(chartEntries[index].key);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('MMM', 'pt_BR')
                                .format(date)
                                .substring(0, 3),
                            style: theme.textTheme.bodySmall!
                                .copyWith(fontSize: 10),
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
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.left);
                      },
                      reservedSize: 32,
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
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: theme.scaffoldBackgroundColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary
                              .withAlpha((255 * 0.2).round()),
                          theme.colorScheme.secondary
                              .withAlpha((255 * 0.05).round()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
