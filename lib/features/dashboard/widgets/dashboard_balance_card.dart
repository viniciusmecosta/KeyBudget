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
        '${isIncrease ? '+ ' : '- '}${percentageChange.abs().toStringAsFixed(1)}%';

    return BalanceCard(
      title: 'Gasto Total do Mês',
      totalValue: viewModel.totalAmountForMonth,
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
                color: theme.colorScheme.onPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
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
                    'vs média',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
