import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';

import '../viewmodel/analysis_viewmodel.dart';

class AnalysisStatsOverviewWidget extends ConsumerWidget {
  const AnalysisStatsOverviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(analysisViewModelProvider);
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
                icon: Icons.calendar_today_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Gasto Total',
                viewModel.totalOverall,
                Theme.of(context).colorScheme.tertiary,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Média Mensal',
                viewModel.averageMonthlyExpense,
                AppTheme.chartColors[2],
                icon: Icons.insights_rounded,
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

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon ?? Icons.analytics,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formattedValue,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
