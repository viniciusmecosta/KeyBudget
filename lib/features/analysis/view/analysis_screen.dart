import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:provider/provider.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _currencyFormatterNoCents =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AnalysisViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise de Despesas'),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildTotalsRow(context, viewModel),
                const SizedBox(height: 16),
                _buildAverageCard(context, viewModel),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Histórico Mensal'),
                const SizedBox(height: 8),
                _buildLineChart(context, viewModel),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Categorias no Mês'),
                const SizedBox(height: 12),
                _buildCategoryMonthSelector(context, viewModel),
                const SizedBox(height: 16),
                _buildCategoryBreakdown(context, viewModel),
              ],
            ),
    );
  }

  Widget _buildTotalsRow(BuildContext context, AnalysisViewModel viewModel) {
    return Row(
      children: [
        Expanded(
            child: _buildTotalCard(context, 'Gasto Total',
                viewModel.totalOverall, AppTheme.primary)),
        const SizedBox(width: 16),
        Expanded(
            child: _buildTotalCard(context, 'Neste Mês',
                viewModel.totalCurrentMonth, AppTheme.secondary)),
      ],
    );
  }

  Widget _buildAverageCard(BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);
    final percentageChange = viewModel.percentageChangeFromLastMonth;
    final hasPreviousMonth = viewModel.lastMonthExpense > 0;

    final isIncrease = percentageChange >= 0;
    final changeText =
        '${isIncrease ? '+' : '-'} ${percentageChange.abs().toStringAsFixed(1)}%';
    final changeColor =
        isIncrease ? AppTheme.positiveChange : AppTheme.negativeChange;

    return Card(
      color: theme.colorScheme.tertiary.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Média Mensal',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.tertiary)),
            const SizedBox(height: 8),
            Text(
              _currencyFormatterNoCents.format(viewModel.averageMonthlyExpense),
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.tertiary),
            ),
            if (hasPreviousMonth) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                    color: changeColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    changeText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: changeColor),
                  )
                ],
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(
      BuildContext context, String title, double value, Color color) {
    final theme = Theme.of(context);
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.bodyLarge?.copyWith(color: color)),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _currencyFormatterNoCents.format(value),
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold));
  }

  double _getRoundedMaxValue(double maxValue) {
    if (maxValue <= 0) return 500;
    const step = 500.0;
    double rounded = (maxValue / step).ceil() * step;
    return rounded == maxValue ? rounded + step : rounded;
  }

  Widget _buildLineChart(BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);
    final data = viewModel.last6MonthsData;
    final chartEntries = data.entries.toList();

    if (chartEntries.isEmpty || chartEntries.every((e) => e.value == 0)) {
      return const SizedBox(
          height: 220,
          child: Center(child: Text("Nenhum dado para exibir no período.")));
    }

    final firstMonth = DateFormat('yyyy-MM').parse(chartEntries.first.key);
    final lastMonth = DateFormat('yyyy-MM').parse(chartEntries.last.key);

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

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: viewModel.canGoToPreviousPeriod
                  ? () => viewModel.changePeriod(1)
                  : null,
            ),
            Text(
              '${DateFormat.yMMM('pt_BR').format(firstMonth)} - ${DateFormat.yMMM('pt_BR').format(lastMonth)}',
              style: theme.textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: viewModel.canGoToNextPeriod
                  ? () => viewModel.changePeriod(-1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: 500,
                getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withOpacity(0.1), strokeWidth: 1),
                getDrawingVerticalLine: (value) => FlLine(
                    color: theme.dividerColor.withOpacity(0.1), strokeWidth: 1),
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
                          DateFormat('MMM', 'pt_BR')
                              .format(date)
                              .substring(0, 3),
                          style:
                              theme.textTheme.bodySmall!.copyWith(fontSize: 10),
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
              maxX: 5,
              minY: 0,
              maxY: roundedMaxValue,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        _currencyFormatter.format(spot.y),
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary]),
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(colors: [
                      AppTheme.primary.withOpacity(0.2),
                      AppTheme.secondary.withOpacity(0.2),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryMonthSelector(
      BuildContext context, AnalysisViewModel viewModel) {
    if (viewModel.availableMonthsForFilter.isEmpty ||
        viewModel.selectedMonthForCategory == null) {
      return const SizedBox.shrink();
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(
        DateFormat.yMMMM('pt_BR').format(viewModel.selectedMonthForCategory!),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () => _showMonthPicker(context, viewModel),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context, AnalysisViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      builder: (bc) => SizedBox(
        height: 300,
        child: ListView.builder(
          itemCount: viewModel.availableMonthsForFilter.length,
          itemBuilder: (context, index) {
            final month = viewModel.availableMonthsForFilter[index];
            return ListTile(
              title: Text(
                DateFormat.yMMMM('pt_BR').format(month),
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              onTap: () {
                viewModel.setSelectedMonthForCategory(month);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(
      BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);
    final data = viewModel.expensesByCategoryForSelectedMonth;

    if (data.isEmpty) {
      return const SizedBox(
          height: 180,
          child: Center(child: Text("Nenhum dado para o mês selecionado.")));
    }

    final total = data.values.fold(0.0, (sum, item) => sum + item);
    final chartData = data.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse?.touchedSection == null) {
                          _touchedPieIndex = -1;
                          return;
                        }
                        _touchedPieIndex = pieTouchResponse!
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 4,
                  centerSpaceRadius: 30,
                  sections: List.generate(chartData.length, (i) {
                    final isTouched = i == _touchedPieIndex;
                    final entry = chartData[i];
                    return PieChartSectionData(
                      color: entry.key.color,
                      value: entry.value,
                      title: '',
                      radius: isTouched ? 60 : 50,
                      badgeWidget:
                          isTouched ? _buildBadge(entry.key.name, theme) : null,
                      badgePositionPercentageOffset: .98,
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: ListView(
                children: data.entries.map((entry) {
                  final percentage =
                      total > 0 ? (entry.value / total) * 100 : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _buildIndicator(
                      color: entry.key.color,
                      text: entry.key.name,
                      value: entry.value,
                      percentage: percentage,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _buildIndicator(
      {required Color color,
      required String text,
      required double value,
      required double percentage}) {
    final formattedValue = _currencyFormatter.format(value);
    return Row(
      children: <Widget>[
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              Text(
                '$formattedValue (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
          ),
        )
      ],
    );
  }
}
