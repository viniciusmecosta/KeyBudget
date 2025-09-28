import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:provider/provider.dart';

import '../viewmodel/analysis_viewmodel.dart';

class AnalysisStatsOverviewWidget extends StatelessWidget {
  const AnalysisStatsOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AnalysisViewModel>(context);
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
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final currencyFormatterNoCents =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

    String formatCurrencyFlexible(double val) {
      if ((val * 100).truncate() % 100 != 0) {
        return currencyFormatter.format(val);
      } else {
        return currencyFormatterNoCents.format(val);
      }
    }

    final String formattedValue = title == 'Gasto Total'
        ? currencyFormatterNoCents.format(value)
        : formatCurrencyFlexible(value);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((255 * 0.1).round()),
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
}
