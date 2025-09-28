import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:provider/provider.dart';

import '../viewmodel/analysis_viewmodel.dart';
import 'empty_chart_state_widget.dart';

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }
}

class CategoryAnalysisSectionWidget extends StatefulWidget {
  const CategoryAnalysisSectionWidget({super.key});

  @override
  State<CategoryAnalysisSectionWidget> createState() =>
      _CategoryAnalysisSectionWidgetState();
}

class _CategoryAnalysisSectionWidgetState
    extends State<CategoryAnalysisSectionWidget> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AnalysisViewModel>(context);
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
              color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primary.withAlpha((255 * 0.1).round()),
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
                        color: theme.colorScheme.onSurface
                            .withAlpha((255 * 0.6).round()),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color:
                    theme.colorScheme.onSurface.withAlpha((255 * 0.4).round()),
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
                color:
                    theme.colorScheme.onSurface.withAlpha((255 * 0.3).round()),
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
                          ? theme.colorScheme.primary
                              .withAlpha((255 * 0.1).round())
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
                                  ? theme.colorScheme.primary
                                      .withAlpha((255 * 0.3).round())
                                  : theme.colorScheme.outline
                                      .withAlpha((255 * 0.1).round()),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                          .withAlpha((255 * 0.2).round())
                                      : theme.colorScheme.outline
                                          .withAlpha((255 * 0.1).round()),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.calendar_month,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface
                                          .withAlpha((255 * 0.6).round()),
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
                                        NumberFormat.currency(
                                                locale: 'pt_BR', symbol: 'R\$')
                                            .format(monthTotal),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withAlpha((255 * 0.6).round()),
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
      return const EmptyChartStateWidget(
          message: 'Nenhuma despesa para exibir no período',
          icon: Icons.pie_chart_outline);
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
          color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
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
                        color: theme.textTheme.bodySmall?.color?.withAlpha(178),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                              locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0)
                          .format(total),
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
          }),
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
              color: theme.colorScheme.onInverseSurface
                  .withAlpha((255 * 0.7).round()),
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
    final formattedValue =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? color.withAlpha((255 * 0.08).round())
                : Colors.transparent,
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
                            color: color.withAlpha((255 * 0.4).round()),
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
                        color: color.withAlpha((255 * 0.15).round()),
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
            color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
          ),
      ],
    );
  }
}
