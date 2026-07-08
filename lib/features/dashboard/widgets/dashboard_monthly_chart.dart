import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

class DashboardMonthlyChart extends ConsumerWidget {
  const DashboardMonthlyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;
    final theme = Theme.of(context);
    final now = DateTime.now();

    final Map<int, double> expensesByMonth = {};
    final Map<int, double> incomesByMonth = {};

    int maxMonthIndexWithData = -1;
    for (var exp in viewModel.allExpenses) {
      if (!enableIncomes && exp.isIncome == true) continue;
      final monthsDifference =
          (now.year - exp.date.year) * 12 + now.month - exp.date.month;
      if (monthsDifference >= 0 && monthsDifference < 4) {
        if (monthsDifference > maxMonthIndexWithData) {
          maxMonthIndexWithData = monthsDifference;
        }
      }
    }

    final int monthsToShow = maxMonthIndexWithData >= 0 ? maxMonthIndexWithData + 1 : 0;

    for (int i = 0; i < monthsToShow; i++) {
      expensesByMonth[i] = 0.0;
      incomesByMonth[i] = 0.0;
    }

    for (var exp in viewModel.allExpenses) {
      if (!enableIncomes && exp.isIncome == true) continue;
      final monthsDifference =
          (now.year - exp.date.year) * 12 + now.month - exp.date.month;
      if (monthsDifference >= 0 && monthsDifference < monthsToShow) {
        if (exp.isIncome == true) {
          incomesByMonth[monthsDifference.toInt()] =
              (incomesByMonth[monthsDifference.toInt()] ?? 0.0) + exp.amount;
        } else {
          expensesByMonth[monthsDifference.toInt()] =
              (expensesByMonth[monthsDifference.toInt()] ?? 0.0) + exp.amount;
        }
      }
    }

    final validMonths = expensesByMonth.keys.toList();
    validMonths.sort((a, b) => b.compareTo(a));

    double maxAmount = 0.0;
    for (int i in validMonths) {
      if (expensesByMonth[i]! > maxAmount) {
        maxAmount = expensesByMonth[i]!;
      }
      if (enableIncomes && incomesByMonth[i]! > maxAmount) {
        maxAmount = incomesByMonth[i]!;
      }
    }

    if (maxAmount == 0) {
      maxAmount = 100;
    }

    final barGroups = List.generate(validMonths.length, (index) {
      final monthKey = validMonths[index];
      final expVal = expensesByMonth[monthKey]!;
      final incVal = incomesByMonth[monthKey]!;
      
      final expenseRod = BarChartRodData(
        toY: expVal,
        color: theme.colorScheme.error,
        width: enableIncomes ? 16 : 28,
        borderRadius: BorderRadius.circular(6),
        backDrawRodData: BackgroundBarChartRodData(
          show: !enableIncomes,
          toY: maxAmount * 1.2,
          color: theme.colorScheme.surfaceContainerHighest
              .withAlpha((255 * 0.5).round()),
        ),
      );

      final incomeRod = BarChartRodData(
        toY: incVal,
        color: Colors.greenAccent[400],
        width: 16,
        borderRadius: BorderRadius.circular(6),
      );

      return BarChartGroupData(
        x: index,
        barsSpace: 2,
        barRods: enableIncomes ? [incomeRod, expenseRod] : [expenseRod.copyWith(color: theme.colorScheme.primary)],
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
                    enableIncomes ? 'Entradas vs Saídas' : 'Gastos Mensais',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthsToShow <= 1 ? 'Último mês' : 'Últimos $monthsToShow meses',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha((255 * 0.15).round()),
                  borderRadius: AppBorders.borderRadiusM,
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
            ],
          ),
          if (enableIncomes) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent[400],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('Entradas', style: theme.textTheme.bodySmall),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text('Saídas', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 100,
            child: validMonths.isEmpty
                ? Center(
                    child: Text(
                      enableIncomes ? 'Nenhum lançamento nos últimos 4 meses' : 'Nenhum gasto nos últimos 4 meses',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxAmount * 1.2,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) =>
                              theme.colorScheme.surface,
                          tooltipBorder: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                          tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final isIncomeRod = enableIncomes && rodIndex == 0;
                            return BarTooltipItem(
                              NumberFormat.currency(
                                      locale: 'pt_BR', symbol: 'R\$')
                                  .format(rod.toY),
                              TextStyle(
                                color: isIncomeRod ? Colors.greenAccent[400] : (enableIncomes ? theme.colorScheme.error : theme.colorScheme.primary),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
                              if (value.toInt() < 0 ||
                                  value.toInt() >= validMonths.length) {
                                return const SizedBox.shrink();
                              }
                              final monthKey = validMonths[value.toInt()];
                              final monthDate =
                                  DateTime(now.year, now.month - monthKey, 1);
                              final monthName = DateFormat.MMM('pt_BR')
                                  .format(monthDate)
                                  .toUpperCase();
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

