import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/balance_card.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/colors/app_colors.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

class DashboardBalanceCard extends ConsumerStatefulWidget {
  const DashboardBalanceCard({super.key});

  @override
  ConsumerState<DashboardBalanceCard> createState() =>
      _DashboardBalanceCardState();
}

class _DashboardBalanceCardState extends ConsumerState<DashboardBalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int _lastSeenRefreshCount = -1;
  double _scheduledTargetTotal = double.nan;
  double _scheduledTargetBalance = double.nan;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.durationSlow,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: AppAnimations.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo({
    required double from,
    required double to,
    required bool enableIncomes,
    required DashboardViewModel viewModel,
  }) {
    viewModel.onAnimationStartedTo(
      total: enableIncomes ? viewModel.lastAnimatedTotalForMonth : to,
      balance: enableIncomes ? to : viewModel.lastAnimatedBalanceForMonth,
    );

    _animation = Tween<double>(
      begin: from,
      end: to,
    ).animate(CurvedAnimation(parent: _controller, curve: AppAnimations.curve));
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final theme = Theme.of(context);
    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;

    final currentValue = enableIncomes
        ? viewModel.balanceForMonth
        : viewModel.totalAmountForMonth;

    final fromValue = enableIncomes
        ? viewModel.lastAnimatedBalanceForMonth
        : viewModel.lastAnimatedTotalForMonth;

    final isNewRefresh = _lastSeenRefreshCount != viewModel.refreshCount;

    if (isNewRefresh) {
      _lastSeenRefreshCount = viewModel.refreshCount;
      _scheduledTargetTotal = viewModel.totalAmountForMonth;
      _scheduledTargetBalance = viewModel.balanceForMonth;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _animateTo(
          from: 0,
          to: currentValue,
          enableIncomes: enableIncomes,
          viewModel: viewModel,
        );
      });
    } else {
      final scheduledTarget = enableIncomes
          ? _scheduledTargetBalance
          : _scheduledTargetTotal;
      if (currentValue != scheduledTarget) {
        _scheduledTargetTotal = viewModel.totalAmountForMonth;
        _scheduledTargetBalance = viewModel.balanceForMonth;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _animateTo(
            from: fromValue,
            to: currentValue,
            enableIncomes: enableIncomes,
            viewModel: viewModel,
          );
        });
      }
    }

    final percentageChange = viewModel.percentageChangeFromAverage(
      enableIncomes,
    );
    final hasPreviousMonths =
        viewModel.averageOfPreviousMonths(enableIncomes) != 0.0;
    final isIncrease = percentageChange >= 0;
    final formattedPercentage =
        '${isIncrease ? '+' : ''}${percentageChange.abs().toStringAsFixed(1)}%';

    final isGood = enableIncomes ? isIncrease : !isIncrease;
    final badgeTextColor = isGood
        ? Colors.greenAccent[400]!
        : Colors.redAccent[200]!;

    final valueSubtitle = hasPreviousMonths
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
              Flexible(
                child: Text(
                  enableIncomes
                      ? 'em relação à média anterior'
                      : 'em relação à média anterior de gastos',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimary.withAlpha(
                      (255 * 0.8).round(),
                    ),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          )
        : Text(
            'Sem histórico anterior para comparação',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimary.withAlpha(
                (255 * 0.75).round(),
              ),
              fontSize: 11,
            ),
          );

    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final primaryHue = HSLColor.fromColor(theme.colorScheme.primary).hue;
        final isGreenish = primaryHue >= 70 && primaryHue <= 160;
        final isReddish = primaryHue >= 330 || primaryHue <= 20;
        final incomeIconColor = isGreenish
            ? theme.colorScheme.onPrimary
            : Colors.greenAccent[400]!;
        final expenseIconColor = isReddish
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.error;

        return BalanceCard(
          title: enableIncomes ? 'Saldo do período' : 'Despesas do mês',
          totalValue: _animation.value,
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              AppColors.getGradientSecondaryColor(theme.colorScheme.primary),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () {
            ref
                .read(navigationViewModelProvider)
                .navigateTo(AppDestination.expenses);
          },
          valueSubtitle: valueSubtitle,
          subtitle: enableIncomes
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_circle_up_rounded,
                            color: incomeIconColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Receitas: ${currencyFormatter.format(viewModel.totalIncomeForMonth)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_circle_down_rounded,
                            color: expenseIconColor,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Despesas: ${currencyFormatter.format(viewModel.totalAmountForMonth)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
