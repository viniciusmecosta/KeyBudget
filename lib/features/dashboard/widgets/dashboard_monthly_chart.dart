import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

class DashboardMonthlyChart extends ConsumerWidget {
  const DashboardMonthlyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final Map<int, double> expensesByMonth = {};
    
    for (int i = 0; i < 7; i++) {
      expensesByMonth[i] = 0.0;
    }

    for (var exp in viewModel.allExpenses) {
      final monthsDifference = (now.year - exp.date.year) * 12 + now.month - exp.date.month;
      if (monthsDifference >= 0 && monthsDifference < 7) {
        expensesByMonth[monthsDifference] = (expensesByMonth[monthsDifference] ?? 0.0) + exp.amount;
      }
    }

    final validMonths = expensesByMonth.entries.where((e) => e.value > 0).toList();
    validMonths.sort((a, b) => b.key.compareTo(a.key));

    double maxMonthlyAmount = 0.0;
    for (var entry in validMonths) {
      if (entry.value > maxMonthlyAmount) {
        maxMonthlyAmount = entry.value;
      }
    }

    if (maxMonthlyAmount == 0) {
      maxMonthlyAmount = 100;
    }

    final barGroups = List.generate(validMonths.length, (index) {
      final data = validMonths[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.value,
            color: theme.colorScheme.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxMonthlyAmount * 1.2,
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    });

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gastos Mensais',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Últimos 7 meses',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 70,
            child: validMonths.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum gasto nos últimos 7 meses',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxMonthlyAmount * 1.2,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => theme.colorScheme.inverseSurface,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(rod.toY),
                              TextStyle(
                                color: theme.colorScheme.onInverseSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < 0 || value.toInt() >= validMonths.length) {
                                return const SizedBox.shrink();
                              }
                              final data = validMonths[value.toInt()];
                              final monthDate = DateTime(now.year, now.month - data.key, 1);
                              final monthName = DateFormat.MMM('pt_BR').format(monthDate).toUpperCase();
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  monthName,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 24,
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
          ),
        ],
      ),
    );
  }
}
