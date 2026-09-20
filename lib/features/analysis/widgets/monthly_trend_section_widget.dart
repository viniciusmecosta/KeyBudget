import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/features/analysis/domain/analysis_snapshot.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

import '../viewmodel/analysis_viewmodel.dart';
import 'empty_chart_state_widget.dart';

class ChartScaleHelper {
  static ({double min, double max, double interval}) calculateNiceScale({
    required double minVal,
    required double maxVal,
    int targetTicks = 5,
    bool forceZeroMin = true,
  }) {
    double min = forceZeroMin ? math.min(0.0, minVal) : minVal;
    double max = maxVal;

    if (max <= min) {
      return (min: 0.0, max: 100.0, interval: 25.0);
    }

    final span = max - min;
    final rawStep = span / targetTicks;
    if (rawStep <= 0) {
      return (min: 0.0, max: 100.0, interval: 25.0);
    }

    final exponent = (math.log(rawStep) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final fraction = rawStep / magnitude;

    double niceStep;
    if (fraction <= 1.5) {
      niceStep = 1.0 * magnitude;
    } else if (fraction <= 3.5) {
      niceStep = 2.0 * magnitude;
    } else if (fraction <= 7.5) {
      niceStep = 5.0 * magnitude;
    } else {
      niceStep = 10.0 * magnitude;
    }

    final niceMin = (min / niceStep).floor() * niceStep;
    var niceMax = (max / niceStep).ceil() * niceStep;
    if (niceMax == max) {
      niceMax += niceStep;
    }

    return (min: niceMin, max: niceMax, interval: niceStep);
  }

  static String formatCompactValue(double value) {
    if (value == 0) return '0';
    final isNegative = value < 0;
    final abs = value.abs();
    String formatted;
    if (abs >= 1000000) {
      formatted = '${(abs / 1000000).toStringAsFixed(1).replaceAll('.0', '')}M';
    } else if (abs >= 1000) {
      formatted = '${(abs / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    } else {
      formatted = abs.toStringAsFixed(0);
    }
    return isNegative ? '-$formatted' : formatted;
  }

  static Set<int> calculateVisibleLabelIndices(int count) {
    if (count <= 6) {
      return {for (int i = 0; i < count; i++) i};
    }
    final step = (count / 5).ceil();
    final indices = <int>{0};
    for (int i = step; i < count - 1; i += step) {
      indices.add(i);
    }
    indices.add(count - 1);
    return indices;
  }
}

class MonthlyTrendSectionWidget extends ConsumerStatefulWidget {
  const MonthlyTrendSectionWidget({super.key});

  @override
  ConsumerState<MonthlyTrendSectionWidget> createState() =>
      _MonthlyTrendSectionWidgetState();
}

class _MonthlyTrendSectionWidgetState
    extends ConsumerState<MonthlyTrendSectionWidget> {
  bool _showTableAlternative = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(analysisViewModelProvider);
    final enableIncomes =
        ref.watch(authViewModelProvider).currentUser?.enableIncomes ?? false;

    final trendSnapshot = viewModel.trendSnapshot;
    final points = trendSnapshot.monthlySeries;

    final bool allEmpty = points.isEmpty ||
        points.every((p) =>
            p.incomeAmount.amountMinor == 0 &&
            p.expenseAmount.amountMinor == 0);

    if (allEmpty) {
      return const EmptyChartStateWidget(
        message: 'Nenhum dado para exibir no gráfico',
        icon: Icons.show_chart,
      );
    }

    final theme = Theme.of(context);
    final rangeText = 'Últimos ${viewModel.trendMonthsCount} meses';

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
                      enableIncomes ? 'Tendência Histórica' : 'Histórico Mensal',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$rangeText • ${enableIncomes ? "Entradas vs Saídas" : "Evolução ao longo do tempo"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
                    DropdownMenuItem(value: 12, child: Text('Últimos 12 meses')),
                    DropdownMenuItem(value: 24, child: Text('Últimos 2 anos')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      viewModel.setTrendMonthsCount(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (enableIncomes)
            _buildDualLineChart(context, points)
          else
            _buildSingleLineChart(context, points),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showTableAlternative = !_showTableAlternative;
                });
              },
              icon: Icon(
                _showTableAlternative
                    ? Icons.visibility_off_outlined
                    : Icons.table_chart_outlined,
                size: 18,
              ),
              label: Text(
                _showTableAlternative
                    ? 'Ocultar tabela'
                    : 'Ver dados em tabela',
              ),
            ),
          ),
          if (_showTableAlternative) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildAccessibleTable(context, points, enableIncomes),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleLineChart(
    BuildContext context,
    List<MonthlyPoint> points,
  ) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final spots = points
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            e.value.expenseAmount.amountMinor / 100.0,
          ),
        )
        .toList();

    double maxVal = 0;
    for (final s in spots) {
      if (s.y > maxVal) maxVal = s.y;
    }

    final scale = ChartScaleHelper.calculateNiceScale(
      minVal: 0,
      maxVal: maxVal,
      forceZeroMin: true,
    );

    final visibleIndices =
        ChartScaleHelper.calculateVisibleLabelIndices(points.length);

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: scale.min,
          maxY: scale.max,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: scale.interval,
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
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (!visibleIndices.contains(index) ||
                      index < 0 ||
                      index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  final point = points[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      point.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: scale.interval,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == scale.max && scale.max > maxVal * 1.05) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      ChartScaleHelper.formatCompactValue(value),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.inverseSurface,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final point = points[index];
                  return LineTooltipItem(
                    '${point.formattedMonthName}\nDespesas: ${currencyFormatter.format(spot.y)}',
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
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 3,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.25),
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

  Widget _buildDualLineChart(
    BuildContext context,
    List<MonthlyPoint> points,
  ) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final incomesSpots = points
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            e.value.incomeAmount.amountMinor / 100.0,
          ),
        )
        .toList();

    final expensesSpots = points
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble(),
            e.value.expenseAmount.amountMinor / 100.0,
          ),
        )
        .toList();

    double maxVal = 0;
    for (final p in points) {
      final inc = p.incomeAmount.amountMinor / 100.0;
      final exp = p.expenseAmount.amountMinor / 100.0;
      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;
    }

    final scale = ChartScaleHelper.calculateNiceScale(
      minVal: 0,
      maxVal: maxVal,
      forceZeroMin: true,
    );

    final visibleIndices =
        ChartScaleHelper.calculateVisibleLabelIndices(points.length);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
              color: Colors.greenAccent[400]!,
              label: 'Receitas',
              theme: theme,
            ),
            const SizedBox(width: AppSpacing.lg),
            _buildLegendItem(
              color: theme.colorScheme.error,
              label: 'Despesas',
              theme: theme,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: scale.min,
              maxY: scale.max,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: scale.interval,
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
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (!visibleIndices.contains(index) ||
                          index < 0 ||
                          index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final point = points[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          point.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: scale.interval,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      if (value == scale.max && scale.max > maxVal * 1.05) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          ChartScaleHelper.formatCompactValue(value),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final point = points[index];
                      final isIncome = spot.bar.color == Colors.greenAccent[400];
                      final title = isIncome ? 'Receitas' : 'Despesas';
                      return LineTooltipItem(
                        '${point.formattedMonthName}\n$title: ${currencyFormatter.format(spot.y)}',
                        TextStyle(
                          color: spot.bar.color,
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
                    color: Colors.greenAccent[400]!.withAlpha(25),
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
                    color: theme.colorScheme.error.withAlpha(25),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibleTable(
    BuildContext context,
    List<MonthlyPoint> points,
    bool enableIncomes,
  ) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: AppBorders.borderRadiusMD,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 44,
          columns: [
            const DataColumn(label: Text('Mês')),
            if (enableIncomes) const DataColumn(label: Text('Receitas')),
            const DataColumn(label: Text('Despesas')),
            if (enableIncomes) const DataColumn(label: Text('Saldo')),
          ],
          rows: points.map((p) {
            return DataRow(
              cells: [
                DataCell(Text(p.formattedMonthName)),
                if (enableIncomes)
                  DataCell(
                    Text(
                      currencyFormatter.format(
                        p.incomeAmount.amountMinor / 100.0,
                      ),
                      style: TextStyle(
                        color: Colors.greenAccent[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                DataCell(
                  Text(
                    currencyFormatter.format(
                      p.expenseAmount.amountMinor / 100.0,
                    ),
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (enableIncomes)
                  DataCell(
                    Text(
                      currencyFormatter.format(
                        p.balanceAmount.amountMinor / 100.0,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: p.balanceAmount.amountMinor >= 0
                            ? Colors.greenAccent[400]
                            : theme.colorScheme.error,
                      ),
                    ),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
