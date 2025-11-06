import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/balance_card.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:provider/provider.dart';

class DashboardBalanceCard extends StatelessWidget {
  const DashboardBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DashboardViewModel>(context);
    final theme = Theme.of(context);

    final percentageChange = viewModel.percentageChangeFromAverage;
    final hasPreviousMonths = viewModel.averageOfPreviousMonths > 0;
    final isIncrease = percentageChange >= 0;
    final formattedPercentage =
        '${isIncrease ? '+ ' : ''}${percentageChange.abs().toStringAsFixed(1)}%';

    return BalanceCard(
      title: 'Gasto Total do Mês',
      totalValue: viewModel.totalAmountForMonth,
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary,
          Color.lerp(
              theme.colorScheme.primary, theme.colorScheme.secondary, 0.4)!,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: () {
        Provider.of<NavigationViewModel>(context, listen: false).selectedIndex =
            1;
      },
      subtitle: hasPreviousMonths
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceM - 2,
                vertical: AppTheme.spaceS - 2,
              ),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onPrimary.withAlpha((255 * 0.15).round()),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncrease
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spaceXS),
                  Text(
                    formattedPercentage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceXS),
                  Text(
                    'em relação à média',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary
                          .withAlpha((255 * 0.8).round()),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
