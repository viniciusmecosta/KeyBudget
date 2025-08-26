import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/expense_category.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dart:math';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        Provider.of<AnalysisViewModel>(context, listen: false)
            .fetchExpenses(authViewModel.currentUser!.id);
      }
    });
  }

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
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Histórico Mensal'),
                const SizedBox(height: 8),
                _buildLineChart(context, viewModel),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Categorias no Mês'),
                const SizedBox(height: 8),
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
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  double _getRoundedMaxValue(double maxValue) {
    if (maxValue <= 0) return 1000;
    if (maxValue < 1000) return 1000;
    if (maxValue < 2000) return 2000;
    final step = 1000;
    return (maxValue / step).ceil() * step.toDouble();
  }

  Widget _buildLineChart(BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);
    final data = viewModel.last12MonthsData;
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
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();

    final maxValue =
        spots.isEmpty ? 0.0 : spots.map((spot) => spot.y).reduce(max);
    final roundedMaxValue = _getRoundedMaxValue(maxValue);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => viewModel.changeYear(-1),
            ),
            Text(
              '${DateFormat.yMMM('pt_BR').format(firstMonth)} - ${DateFormat.yMMM('pt_BR').format(lastMonth)}',
              style: theme.textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => viewModel.changeYear(1),
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
                horizontalInterval:
                    roundedMaxValue > 0 ? roundedMaxValue / 4 : 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: theme.dividerColor.withOpacity(0.1),
                    strokeWidth: 1,
                  );
                },
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
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= chartEntries.length || index % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      final date =
                          DateFormat('yyyy-MM').parse(chartEntries[index].key);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('MMM', 'pt_BR').format(date),
                            style: theme.textTheme.bodySmall),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: roundedMaxValue > 0 ? roundedMaxValue / 4 : 1,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max && meta.max != 0) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                          '${(value / 1000).toStringAsFixed(value > 0 && value < 1000 ? 1 : 0)}k',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.left);
                    },
                    reservedSize: 32,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 11,
              minY: 0,
              maxY: roundedMaxValue,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                  ),
                  barWidth: 5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.2),
                        AppTheme.secondary.withOpacity(0.2)
                      ],
                    ),
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
    final availableMonths = viewModel.availableMonthsForFilter;
    if (availableMonths.isEmpty || viewModel.selectedMonthForCategory == null) {
      return const SizedBox.shrink();
    }

    return ActionChip(
      avatar: const Icon(Icons.calendar_today, size: 18),
      label: Text(
        DateFormat.yMMMM('pt_BR').format(viewModel.selectedMonthForCategory!),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: availableMonths.length,
                itemBuilder: (context, index) {
                  final month = availableMonths[index];
                  return ListTile(
                    title: Text(DateFormat.yMMMM('pt_BR').format(month)),
                    onTap: () {
                      viewModel.setSelectedMonthForCategory(month);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryBreakdown(
      BuildContext context, AnalysisViewModel viewModel,
      {Key? key}) {
    final theme = Theme.of(context);
    final data = viewModel.expensesByCategoryForSelectedMonth;

    if (data.isEmpty) {
      return const SizedBox(
          height: 180,
          child: Center(child: Text("Nenhum dado para o mês selecionado.")));
    }

    final total = data.values.fold(0.0, (sum, item) => sum + item);

    return Card(
      key: key,
      elevation: 0,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          // Envolve a Row com um SizedBox para dar uma altura fixa
          height: 180,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 30,
                    sections: data.entries.map((entry) {
                      final category = entry.key;
                      final value = entry.value;
                      return PieChartSectionData(
                        color: category.getColor(theme),
                        value: value,
                        title: '',
                        radius: 40,
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.entries.map((entry) {
                    final percentage =
                        total > 0 ? (entry.value / total) * 100 : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildIndicator(
                        color: entry.key.getColor(theme),
                        text: entry.key.displayName,
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
      ),
    );
  }

  Widget _buildIndicator({
    required Color color,
    required String text,
    required double value,
    required double percentage,
  }) {
    return Row(
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${_currencyFormatterNoCents.format(value)} (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
