import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/balance_card.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

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

    final percentageChange = viewModel.percentageChangeFromAverage;
    final hasPreviousMonths = viewModel.averageOfPreviousMonths > 0;
    final isIncrease = percentageChange >= 0;
    final formattedPercentage =
        '${isIncrease ? '+ ' : ''}${percentageChange.abs().toStringAsFixed(1)}%';

    return TweenAnimationBuilder<double>(
      key: ValueKey(viewModel.totalAmountForMonth),
      tween: Tween<double>(begin: 0, end: viewModel.totalAmountForMonth),
      duration: AppAnimations.durationSlow,
      curve: AppAnimations.curve,
      builder: (context, value, child) {
        return BalanceCard(
          title: 'Gasto Total do Mês',
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
          subtitle: hasPreviousMonths
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceS,
                          vertical: AppTheme.spaceXS),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary
                            .withAlpha((255 * 0.1).round()),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isIncrease
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: theme.colorScheme.onPrimary,
                            size: 14,
                          ),
                          const SizedBox(width: AppTheme.spaceXS),
                          Text(
                            formattedPercentage,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    Text(
                      'em relação à média',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimary
                            .withAlpha((255 * 0.7).round()),
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
