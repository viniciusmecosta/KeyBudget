import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:provider/provider.dart';

class TotalBalanceCard extends StatelessWidget {
  const TotalBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DashboardViewModel>(context);
    final theme = Theme.of(context);
    final percentageChange = viewModel.percentageChangeFromAverage;
    final hasPreviousMonths = viewModel.averageOfPreviousMonths > 0;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final isIncrease = percentageChange >= 0;
    final formattedPercentage =
        '${isIncrease ? '+' : '-'}${percentageChange.abs().toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: InkWell(
          onTap: () {
            Provider.of<NavigationViewModel>(context, listen: false)
                .selectedIndex = 1;
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gasto Total do Mês',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  theme.colorScheme.onPrimary.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceS),
                          Text(
                            currencyFormatter
                                .format(viewModel.totalAmountForMonth),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.onPrimary,
                              fontSize: 30,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceM - 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                if (hasPreviousMonths) ...[
                  const SizedBox(height: AppTheme.spaceL),
                  Container(
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
                            color:
                                theme.colorScheme.onPrimary.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
