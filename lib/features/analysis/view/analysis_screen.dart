import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:provider/provider.dart';

import '../../analysis/viewmodel/analysis_viewmodel.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Análise Financeira',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: viewModel.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Analisando seus dados...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
              )
            : RefreshIndicator(
                onRefresh: () async {},
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppTheme.defaultPadding),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStatsOverview(context, viewModel)
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 100))
                              .slideY(begin: 0.3, end: 0),
                          const SizedBox(height: AppTheme.spaceXL),
                          _buildSectionHeader(context, 'Histórico Mensal',
                                  'Acompanhe sua evolução ao longo do tempo')
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 200))
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: AppTheme.spaceM),
                          _buildMonthlyTrendSection(context, viewModel)
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 300))
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: AppTheme.spaceXL),
                          _buildSectionHeader(context, 'Análise por Categoria',
                                  'Entenda onde seu dinheiro é gasto')
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 400))
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: AppTheme.spaceM),
                          _buildCategoryAnalysisSection(context, viewModel)
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 500))
                              .slideY(begin: 0.2, end: 0),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(
      BuildContext context, AnalysisViewModel viewModel) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Este Mês',
                viewModel.totalCurrentMonth,
                Theme.of(context).colorScheme.primary,
                icon: Icons.calendar_month,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Mês Passado',
                viewModel.lastMonthExpense,
                Theme.of(context).colorScheme.secondary,
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
                Theme.of(context).colorScheme.tertiary,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: AppTheme.spaceM),
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Média Mensal',
                viewModel.averageMonthlyExpense,
                AppTheme.chartColors[2],
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

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon ?? Icons.analytics,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
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
      ),
    );
  }

  Widget _buildMonthlyTrendSection(
      BuildContext context, AnalysisViewModel viewModel) {
    final data = viewModel.lastNMonthsData;
    final chartEntries = data.entries.toList();
    if (chartEntries.isEmpty || chartEntries.every((e) => e.value == 0)) {
      return _buildEmptyChartState(
          context, 'Nenhum dado para exibir no gráfico', Icons.show_chart);
    }
    return Column(
      children: [
        _buildPeriodSelector(context, viewModel),
        const SizedBox(height: AppTheme.spaceM),
        _buildLineChart(context, viewModel),
      ],
    );
  }

  Widget _buildEmptyChartState(
      BuildContext context, String message, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icon,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Suas transações aparecerão aqui assim que forem registradas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
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
          color: theme.colorScheme.outline.withOpacity(0.1),
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
                                color:
                                    theme.colorScheme.outline.withOpacity(0.2),
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
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceS),
              ],
              Expanded(
                child: Material(
                  color: viewModel.useCustomRange
                      ? theme.colorScheme.secondary.withOpacity(0.1)
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
                              ? theme.colorScheme.secondary.withOpacity(0.3)
                              : theme.colorScheme.outline.withOpacity(0.2),
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
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
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
                foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
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
        SnackBar(
          content: const Text('Nenhum dado disponível para seleção'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
      return _buildEmptyChartState(
          context, 'Nenhum dado para exibir', Icons.show_chart);
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
          color: theme.colorScheme.outline.withOpacity(0.1),
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
                    getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final monthKey = chartEntries[index].key;
                        final date = DateFormat('yyyy-MM').parse(monthKey);
                        return LineTooltipItem(
                          '${DateFormat.yMMM('pt_BR').format(date)}\n${_currencyFormatter.format(spot.y)}',
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
                          theme.colorScheme.primary.withOpacity(0.2),
                          theme.colorScheme.secondary.withOpacity(0.05),
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

  Widget _buildCategoryAnalysisSection(
      BuildContext context, AnalysisViewModel viewModel) {
    return Column(
      children: [
        _buildCategoryMonthSelector(context, viewModel),
        const SizedBox(height: AppTheme.spaceM),
        _buildEnhancedCategoryBreakdown(context, viewModel),
      ],
    );
  }

  Widget _buildCategoryMonthSelector(
      BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);

    if (viewModel.availableMonthsForFilter.isEmpty ||
        viewModel.selectedMonthForCategory == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _showMonthPicker(context, viewModel),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Período Selecionado',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMM('pt_BR')
                          .format(viewModel.selectedMonthForCategory!)
                          .capitalize(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bc) => SizedBox(
        height: 400,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              child: Text(
                'Selecionar Período',
                style: theme.textTheme.titleLarge?.copyWith(
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

                  final monthExpenses = viewModel.allExpenses.where(
                    (exp) =>
                        exp.date.year == month.year &&
                        exp.date.month == month.month,
                  );

                  final monthTotal = monthExpenses.fold(
                    0.0,
                    (sum, exp) => sum + exp.amount,
                  );

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceM,
                      vertical: 4,
                    ),
                    child: Material(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          viewModel.setSelectedMonthForCategory(month);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.3)
                                  : theme.colorScheme.outline.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                          .withOpacity(0.2)
                                      : theme.colorScheme.outline
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_month,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat.yMMMM('pt_BR')
                                          .format(month)
                                          .capitalize(),
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (monthTotal > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _currencyFormatter.format(monthTotal),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
      return _buildEmptyChartState(context,
          'Nenhuma despesa para exibir no período', Icons.pie_chart_outline);
    }

    final total = data.values.fold(0.0, (sum, item) => sum + item);
    final chartData = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final showPercentageInChart = chartData.length <= 5;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
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
                    sectionsSpace: showPercentageInChart ? 2 : 1,
                    centerSpaceRadius: 50,
                    sections: List.generate(chartData.length, (i) {
                      final isTouched = i == _touchedPieIndex;
                      final entry = chartData[i];
                      final percentage = (entry.value / total) * 100;

                      return PieChartSectionData(
                        color: entry.key.color,
                        value: entry.value,
                        title: showPercentageInChart
                            ? '${percentage.toStringAsFixed(0)}%'
                            : '',
                        radius: isTouched ? 75 : 65,
                        titleStyle: TextStyle(
                          fontSize: showPercentageInChart ? 14 : 0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: showPercentageInChart
                              ? [
                                  const Shadow(
                                    color: Colors.black26,
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        badgeWidget: isTouched && !showPercentageInChart
                            ? _buildTouchBadge(entry.key.name, percentage)
                            : null,
                        badgePositionPercentageOffset: 1.3,
                      );
                    }),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      _currencyFormatterNoCents.format(total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spaceL),
          ...chartData.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final percentage = (category.value / total) * 100;
            final isHighlighted = index == _touchedPieIndex;

            return _buildImprovedLegendItem(
              context: context,
              color: category.key.color,
              name: category.key.name,
              value: category.value,
              percentage: percentage,
              isHighlighted: isHighlighted,
              showDivider: index < chartData.length - 1,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTouchBadge(String name, double percentage) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: theme.colorScheme.onInverseSurface,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: theme.colorScheme.onInverseSurface.withOpacity(0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovedLegendItem({
    required BuildContext context,
    required Color color,
    required String name,
    required double value,
    required double percentage,
    required bool isHighlighted,
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);
    final formattedValue = _currencyFormatter.format(value);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isHighlighted ? color.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: isHighlighted
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isHighlighted ? FontWeight.bold : FontWeight.w500,
                    color: isHighlighted ? color : theme.colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formattedValue,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
      ],
    );
  }
}
