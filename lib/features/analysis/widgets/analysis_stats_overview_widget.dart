import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';

import '../viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class AnalysisStatsOverviewWidget extends ConsumerWidget {
  const AnalysisStatsOverviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(analysisViewModelProvider);
    final enableIncomes = ref.watch(authViewModelProvider).currentUser?.enableIncomes ?? false;

    if (enableIncomes) {
      return _buildIncomesLayout(context, viewModel);
    }
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

  Widget _buildIncomesLayout(BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);
    final balanceChange = viewModel.balancePercentageChangeFromLastMonth;
    final balanceDiff = viewModel.balanceCurrentMonth - viewModel.lastMonthBalance;

    return Column(
      children: [
        _buildEnhancedStatCard(
          context,
          'Saldo Líquido',
          viewModel.balanceCurrentMonth,
          theme.colorScheme.primary,
          icon: Icons.account_balance_wallet_rounded,
          percentageChange: balanceChange,
          absoluteChange: balanceDiff,
          isFullWidth: true,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Entradas',
                viewModel.incomesCurrentMonth,
                Colors.greenAccent[400]!,
                icon: Icons.arrow_circle_up_rounded,
                percentageChange: viewModel.incomesPercentageChangeFromLastMonth,
                absoluteChange: viewModel.incomesCurrentMonth - viewModel.lastMonthIncome,
                invertColors: true,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildEnhancedStatCard(
                context,
                'Saídas',
                viewModel.totalCurrentMonth,
                theme.colorScheme.error,
                icon: Icons.arrow_circle_down_rounded,
                percentageChange: viewModel.percentageChangeFromLastMonth,
                absoluteChange: viewModel.totalCurrentMonth - viewModel.lastMonthExpense,
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
    double? percentageChange,
    double? absoluteChange,
    bool isFullWidth = false,
    bool invertColors = false,
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

    final String formattedValue = (title == 'Gasto Total' || title == 'Saldo Líquido')
        ? formatCurrencyFlexible(value)
        : formatCurrencyFlexible(value);

    Widget? badgeWidget;
    if (percentageChange != null && absoluteChange != null) {
      final isIncrease = percentageChange > 0;
      final isZero = percentageChange == 0.0;
      final bool isGood = invertColors ? isIncrease : !isIncrease;
      
      final badgeColor = isZero 
          ? theme.colorScheme.onSurfaceVariant 
          : (isGood ? Colors.greenAccent[400]! : Colors.redAccent[400]!);
          
      final arrowIcon = isZero 
          ? Icons.remove_rounded 
          : (isIncrease ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded);

      badgeWidget = Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor.withAlpha((255 * 0.15).round()),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(arrowIcon, size: 12, color: badgeColor),
            const SizedBox(width: 4),
            Text(
              '${percentageChange.abs().toStringAsFixed(1)}% (${formatCurrencyFlexible(absoluteChange.abs())})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

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
                  color: color.withAlpha((255 * 0.15).round()),
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
          ?badgeWidget,
        ],
      ),
    );
  }
}
