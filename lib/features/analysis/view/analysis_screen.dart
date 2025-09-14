import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:provider/provider.dart';

import '../viewmodel/analysis_viewmodel.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _currencyFormatterNoCents =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);
  int _touchedPieIndex = -1;

  String _formatCurrencyFlexible(double value) {
    if ((value * 100).truncate() % 100 != 0) {
      return _currencyFormatter.format(value);
    } else {
      return _currencyFormatterNoCents.format(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AnalysisViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise de Despesas'),
      ),
      body: SafeArea(
        child: viewModel.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Analisando seus dados...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {},
                color: AppTheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsOverview(context, viewModel),
                      const SizedBox(height: AppTheme.spaceL),
                      _buildMonthlyTrendSection(context, viewModel),
                      const SizedBox(height: AppTheme.spaceL),
                      _buildCategoryAnalysisSection(context, viewModel),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
      ),
    );
  }

  Widget _buildStatsOverview(
      BuildContext context, AnalysisViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Este Mês',
                viewModel.totalCurrentMonth,
                AppTheme.secondary,
                icon: Icons.calendar_month,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Mês Passado',
                viewModel.lastMonthExpense,
                AppTheme.chartColors[4],
                icon: Icons.history_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceM),
        Row(
          children: [
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Gasto Total',
                viewModel.totalOverall,
                AppTheme.primary,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Média Mensal',
                viewModel.averageMonthlyExpense,
                Theme.of(context).colorScheme.tertiary,
                icon: Icons.insights,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard(
    BuildContext context,
    String title,
    double value,
    Color color, {
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final String formattedValue = title == 'Gasto Total'
        ? _currencyFormatterNoCents.format(value)
        : _formatCurrencyFlexible(value);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.spaceM),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 18),
                const SizedBox(width: AppTheme.spaceS),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formattedValue,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendSection(
      BuildContext context, AnalysisViewModel viewModel) {
    final data = viewModel.lastNMonthsData;
    final chartEntries = data.entries.toList();
    if (chartEntries.isEmpty || chartEntries.every((e) => e.value == 0)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Histórico Mensal',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spaceS),
        _buildPeriodSelector(context, viewModel),
        const SizedBox(height: AppTheme.spaceM),
        _buildLineChart(context, viewModel),
      ],
    );
  }

  Widget _buildPeriodSelector(
      BuildContext context, AnalysisViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${count}M',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              if (!viewModel.useCustomRange) ...[
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: viewModel.canGoToPreviousPeriod
                      ? () => viewModel.changePeriod(1)
                      : null,
                  color: AppTheme.primary,
                ),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCustomRangePicker(context, viewModel),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: viewModel.useCustomRange
                          ? AppTheme.secondary.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: viewModel.useCustomRange
                          ? Border.all(
                              color: AppTheme.secondary.withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (viewModel.useCustomRange) ...[
                          Icon(Icons.date_range,
                              size: 16, color: AppTheme.secondary),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            viewModel.currentPeriodLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: viewModel.useCustomRange
                                  ? AppTheme.secondary
                                  : AppTheme.primary,
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
              if (!viewModel.useCustomRange) ...[
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: viewModel.canGoToNextPeriod
                      ? () => viewModel.changePeriod(-1)
                      : null,
                  color: AppTheme.primary,
                ),
              ],
            ],
          ),
          if (viewModel.useCustomRange) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => viewModel.clearCustomRange(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Voltar ao padrão'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum dado disponível para seleção')),
      );
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
                  primary: AppTheme.primary,
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
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey),
              SizedBox(height: AppTheme.spaceS),
              Text("Nenhum dado para exibir no período."),
            ],
          ),
        ),
      );
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.dividerColor.withOpacity(0.1),
                      strokeWidth: 1),
                  getDrawingVerticalLine: (value) => FlLine(
                      color: theme.dividerColor.withOpacity(0.1),
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
                    getTooltipColor: (_) => Colors.blueGrey.withOpacity(0.8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final monthKey = chartEntries[index].key;
                        final date = DateFormat('yyyy-MM').parse(monthKey);
                        return LineTooltipItem(
                          '${DateFormat.yMMM('pt_BR').format(date)}\n${_currencyFormatter.format(spot.y)}',
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
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.primary,
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
                          AppTheme.primary.withOpacity(0.3),
                          AppTheme.secondary.withOpacity(0.1),
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

  Widget _buildPeriodStats(BuildContext context, AnalysisViewModel viewModel) {
    final stats = viewModel.currentPeriodStats;
    return Row(
      children: [
        Expanded(
          child: _buildMiniStatCard(
            'Total',
            _currencyFormatterNoCents.format(stats['total']!),
            AppTheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStatCard(
            'Média',
            _formatCurrencyFlexible(stats['average']!),
            AppTheme.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStatCard(
            'Maior',
            _formatCurrencyFlexible(stats['highest']!),
            AppTheme.chartColors[2],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMiniStatCard(
            'Menor',
            _formatCurrencyFlexible(stats['lowest']!),
            AppTheme.chartColors[3],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryAnalysisSection(
      BuildContext context, AnalysisViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análise por Categoria',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppTheme.spaceM),
        _buildCategoryMonthSelector(context, viewModel),
        const SizedBox(height: 20),
        _buildEnhancedCategoryBreakdown(context, viewModel),
      ],
    );
  }

  Widget _buildCategoryMonthSelector(
      BuildContext context, AnalysisViewModel viewModel) {
    if (viewModel.availableMonthsForFilter.isEmpty ||
        viewModel.selectedMonthForCategory == null) {
      return const SizedBox.shrink();
    }
    return OutlinedButton(
      onPressed: () => _showMonthPicker(context, viewModel),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.spaceL),
        ),
        side: BorderSide(
          color: AppTheme.primary.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(
            DateFormat.yMMMM('pt_BR')
                .format(viewModel.selectedMonthForCategory!)
                .capitalize(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
        ],
      ),
    );
  }

  void _showMonthPicker(BuildContext context, AnalysisViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.spaceL)),
      ),
      builder: (bc) => SizedBox(
        height: 320,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              child: Text(
                'Selecionar Mês para Análise de Categorias',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: viewModel.availableMonthsForFilter.length,
                itemBuilder: (context, index) {
                  final month = viewModel.availableMonthsForFilter[index];
                  final isSelected =
                      month == viewModel.selectedMonthForCategory;
                  final monthExpenses = viewModel.allExpenses.where((exp) =>
                      exp.date.year == month.year &&
                      exp.date.month == month.month);
                  final monthTotal =
                      monthExpenses.fold(0.0, (sum, exp) => sum + exp.amount);

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppTheme.primary.withOpacity(0.1),
                    leading: Icon(
                      Icons.calendar_month,
                      color: isSelected ? AppTheme.primary : Colors.grey[600],
                    ),
                    title: Text(
                      DateFormat.yMMMM('pt_BR').format(month).capitalize(),
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppTheme.primary : null,
                      ),
                    ),
                    subtitle: monthTotal > 0
                        ? Text(
                            _currencyFormatter.format(monthTotal),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? Icon(Icons.check_circle,
                            color: AppTheme.primary, size: 20)
                        : null,
                    onTap: () {
                      viewModel.setSelectedMonthForCategory(month);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedCategoryBreakdown(
      BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);
    final data = viewModel.expensesByCategoryForSelectedMonth;
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppTheme.spaceM),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: AppTheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                "Nenhuma despesa encontrada",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primary.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "para o mês selecionado",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final total = data.values.fold(0.0, (sum, item) => sum + item);
    final chartData = data.entries.toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceS),
      child: Column(
        children: [
          SizedBox(
            height: 200,
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
                      _touchedPieIndex =
                          pieTouchResponse!.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(chartData.length, (i) {
                  final isTouched = i == _touchedPieIndex;
                  final entry = chartData[i];
                  final percentage =
                      total > 0 ? (entry.value / total) * 100 : 0.0;
                  return PieChartSectionData(
                    color: entry.key.color,
                    value: entry.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: isTouched ? 70 : 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chartData.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = chartData[index];
              final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
              return _buildEnhancedIndicator(
                color: entry.key.color,
                text: entry.key.name,
                value: entry.value,
                percentage: percentage,
                isHighlighted: index == _touchedPieIndex,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedIndicator({
    required Color color,
    required String text,
    required double value,
    required double percentage,
    bool isHighlighted = false,
  }) {
    final formattedValue = _currencyFormatter.format(value);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border:
            isHighlighted ? Border.all(color: color.withOpacity(0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: AppTheme.spaceM,
            height: AppTheme.spaceM,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.w600,
                    color: isHighlighted ? color : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      formattedValue,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.spaceS),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.trending_up,
                size: 12,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}
