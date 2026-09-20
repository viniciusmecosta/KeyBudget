import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/features/analysis/domain/analysis_snapshot.dart';

import '../viewmodel/analysis_viewmodel.dart';
import 'empty_chart_state_widget.dart';

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return substring(0, 1).toUpperCase() + substring(1);
  }
}

class CategoryAnalysisSectionWidget extends ConsumerStatefulWidget {
  const CategoryAnalysisSectionWidget({super.key});

  @override
  ConsumerState<CategoryAnalysisSectionWidget> createState() =>
      _CategoryAnalysisSectionWidgetState();
}

class _CategoryAnalysisSectionWidgetState
    extends ConsumerState<CategoryAnalysisSectionWidget> {
  int _touchedPieIndex = -1;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(analysisViewModelProvider);
    final theme = Theme.of(context);
    final snapshot = viewModel.currentSnapshot;
    final groups = snapshot.categoryDistribution;

    final totalCents = snapshot.totalExpenses.amountMinor;

    if (groups.isEmpty || totalCents <= 0) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Composição de Gastos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const EmptyChartStateWidget(
              message: 'Nenhuma despesa para exibir no período',
              icon: Icons.pie_chart_outline,
            ),
          ],
        ),
      );
    }

    final totalValue = Money.fromCents(totalCents).toDouble();
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final bool hasMoreThan5 = groups.length > 5;
    final List<AnalysisCategoryGroup> top5 =
        hasMoreThan5 ? groups.sublist(0, 5) : groups;

    final int othersCents = hasMoreThan5
        ? groups
            .sublist(5)
            .fold<int>(0, (sum, g) => sum + g.totalAmount.amountMinor)
        : 0;
    final double othersPercentage = hasMoreThan5
        ? groups.sublist(5).fold<double>(0.0, (sum, g) => sum + g.percentage)
        : 0.0;

    final List<PieChartSectionData> pieSections = [];
    for (int i = 0; i < top5.length; i++) {
      final g = top5[i];
      final isTouched = i == _touchedPieIndex;
      final val = g.totalAmount.amountMinor / 100.0;
      final color = Color(g.colorValue);

      pieSections.add(
        PieChartSectionData(
          color: color,
          value: val,
          title: top5.length <= 4 ? '${g.percentage.toStringAsFixed(0)}%' : '',
          radius: isTouched ? 65 : 55,
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
          badgeWidget: isTouched
              ? _buildTouchBadge(g.categoryName, g.percentage)
              : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }

    if (hasMoreThan5 && othersCents > 0) {
      final othersIndex = top5.length;
      final isTouched = othersIndex == _touchedPieIndex;
      final othersColor = theme.colorScheme.outline;

      pieSections.add(
        PieChartSectionData(
          color: othersColor,
          value: othersCents / 100.0,
          title: '',
          radius: isTouched ? 65 : 55,
          badgeWidget: isTouched
              ? _buildTouchBadge('Outras', othersPercentage)
              : null,
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }

    final displayedGroups =
        (_isExpanded || !hasMoreThan5) ? groups : top5;

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
                    'Composição de Gastos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Distribuição por categoria',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (hasMoreThan5)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Text(
                    _isExpanded
                        ? 'Mostrar top 5'
                        : 'Ver todas (${groups.length})',
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
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
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 50,
                    sections: pieSections,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(totalValue),
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
          const SizedBox(height: AppSpacing.xl),
          ...displayedGroups.asMap().entries.map((entry) {
            final index = entry.key;
            final group = entry.value;
            final isHighlighted = index == _touchedPieIndex;
            final color = Color(group.colorValue);

            return _buildCategoryLegendRow(
              context: context,
              color: color,
              name: group.categoryName,
              valueText: group.totalAmount.formatBrl(),
              percentage: group.percentage,
              itemsCount: group.itemsCount,
              isHighlighted: isHighlighted,
              showDivider: index < displayedGroups.length - 1 ||
                  (!_isExpanded && hasMoreThan5),
            );
          }),
          if (!_isExpanded && hasMoreThan5)
            _buildCategoryLegendRow(
              context: context,
              color: theme.colorScheme.outline,
              name: 'Outras categorias (${groups.length - 5})',
              valueText: Money.fromCents(othersCents).formatBrl(),
              percentage: othersPercentage,
              itemsCount: groups.sublist(5).fold<int>(0, (s, g) => s + g.itemsCount),
              isHighlighted: top5.length == _touchedPieIndex,
              showDivider: false,
            ),
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
        borderRadius: AppBorders.borderRadiusS,
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
              color: theme.colorScheme.onInverseSurface.withAlpha(200),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegendRow({
    required BuildContext context,
    required Color color,
    required String name,
    required String valueText,
    required double percentage,
    required int itemsCount,
    required bool isHighlighted,
    required bool showDivider,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? color.withAlpha((255 * 0.08).round())
                : Colors.transparent,
            borderRadius: AppBorders.borderRadiusS,
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
                            color: color.withAlpha(100),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isHighlighted
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isHighlighted ? color : theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$itemsCount ${itemsCount == 1 ? "registro" : "registros"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      valueText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
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
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
      ],
    );
  }
}
