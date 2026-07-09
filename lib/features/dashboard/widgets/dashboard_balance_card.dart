import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/balance_card.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:intl/intl.dart';

class DashboardBalanceCard extends ConsumerStatefulWidget {
  const DashboardBalanceCard({super.key});

  @override
  ConsumerState<DashboardBalanceCard> createState() =>
      _DashboardBalanceCardState();
}

class _DashboardBalanceCardState extends ConsumerState<DashboardBalanceCard> {
  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final theme = Theme.of(context);

    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;

    final percentageChange = viewModel.percentageChangeFromAverage(enableIncomes);
    final hasPreviousMonths = viewModel.averageOfPreviousMonths(enableIncomes) != 0.0;
    final isIncrease = percentageChange >= 0;
    final formattedPercentage =
        '${isIncrease ? '+' : ''}${percentageChange.abs().toStringAsFixed(1)}%';

    final isGood = enableIncomes ? isIncrease : !isIncrease;
    final badgeTextColor = isGood ? Colors.greenAccent[400]! : Colors.redAccent[200]!;

    final valueSubtitle = hasPreviousMonths
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeTextColor.withAlpha((255 * 0.15).round()),
                  borderRadius: AppBorders.borderRadiusS,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncrease
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: badgeTextColor,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      formattedPercentage,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                enableIncomes ? 'em relação à média de saldo' : 'em relação à média de gastos',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withAlpha((255 * 0.8).round()),
                  fontSize: 11,
                ),
              ),
            ],
          )
        : null;

    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return TweenAnimationBuilder<double>(
      key: ValueKey(enableIncomes ? viewModel.balanceForMonth : viewModel.totalAmountForMonth),
      tween: Tween<double>(begin: 0, end: enableIncomes ? viewModel.balanceForMonth : viewModel.totalAmountForMonth),
      duration: AppAnimations.durationSlow,
      curve: AppAnimations.curve,
      builder: (context, value, child) {
        return BalanceCard(
          title: enableIncomes ? 'Saldo do Mês' : 'Gasto Total do Mês',
          totalValue: value,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              const Color(0xFF3B82F6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () {
            ref.read(navigationViewModelProvider).selectedIndex = 1;
          },
          valueSubtitle: valueSubtitle,
          subtitle: enableIncomes ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.arrow_circle_up_rounded, color: Colors.greenAccent[400], size: 18),
                    const SizedBox(width: 6),
                    Text(
                      currencyFormatter.format(viewModel.totalIncomeForMonth),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Icon(Icons.arrow_circle_down_rounded, color: theme.colorScheme.error, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      currencyFormatter.format(viewModel.totalAmountForMonth),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ) : null,
        );
      },
    );
  }
}
