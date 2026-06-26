import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

class DashboardWeeklyChart extends ConsumerWidget {
  const DashboardWeeklyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final theme = Theme.of(context);

    // Filter expenses for the last 7 days
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));
    final startOfSevenDaysAgo =
        DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    final recentExpenses = viewModel.allExpenses.where((exp) {
      return exp.date.isAfter(startOfSevenDaysAgo) ||
          exp.date.isAtSameMomentAs(startOfSevenDaysAgo);
    }).toList();

    // Group by day
    final Map<int, double> expensesByDay = {};
    for (int i = 0; i < 7; i++) {
      expensesByDay[i] = 0.0;
    }

    double maxDailyAmount = 0.0;

    for (var exp in recentExpenses) {
      final difference = exp.date.difference(startOfSevenDaysAgo).inDays;
      if (difference >= 0 && difference < 7) {
        expensesByDay[difference] = (expensesByDay[difference] ?? 0.0) + exp.amount;
        if (expensesByDay[difference]! > maxDailyAmount) {
          maxDailyAmount = expensesByDay[difference]!;
        }
      }
    }

    if (maxDailyAmount == 0) {
      maxDailyAmount = 100; // default scale if no data
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimos 7 dias',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.bar_chart_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxDailyAmount * 1.2, // 20% padding at top
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => theme.colorScheme.inverseSurface,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tooltipMargin: 8,
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
                        final date = startOfSevenDaysAgo.add(Duration(days: value.toInt()));
                        final dayName = DateFormat.E('pt_BR').format(date).substring(0, 3);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dayName.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
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
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: expensesByDay[index] ?? 0.0,
                        color: theme.colorScheme.primary,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxDailyAmount * 1.2,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
