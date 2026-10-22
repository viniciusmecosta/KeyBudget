import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/balance_card.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/colors/app_contrast.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

class DashboardBalanceCard extends ConsumerStatefulWidget {
  const DashboardBalanceCard({super.key, this.integrated = false});

  final bool integrated;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.isReducedMotion(context)) {
      _controller.value = 1;
    }
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
      begin: AppAnimations.isReducedMotion(context) ? to : from,
      end: to,
    ).animate(CurvedAnimation(parent: _controller, curve: AppAnimations.curve));
    if (AppAnimations.isReducedMotion(context)) {
      _controller.value = 1;
      return;
    }
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final theme = Theme.of(context);
    const cardTextColor = Colors.white;
    final authViewModel = ref.watch(authViewModelProvider);
    final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;

    final currentValue = enableIncomes
        ? viewModel.realizedBalanceForMonth
        : viewModel.totalAmountForMonth;

    final fromValue = enableIncomes
        ? viewModel.lastAnimatedBalanceForMonth
        : viewModel.lastAnimatedTotalForMonth;

    final isNewRefresh = _lastSeenRefreshCount != viewModel.refreshCount;

    if (isNewRefresh) {
      _lastSeenRefreshCount = viewModel.refreshCount;
      _scheduledTargetTotal = viewModel.totalAmountForMonth;
      _scheduledTargetBalance = viewModel.realizedBalanceForMonth;
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
        _scheduledTargetBalance = viewModel.realizedBalanceForMonth;
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
        '${isIncrease ? '+' : '−'}${percentageChange.abs().toStringAsFixed(1)}%';

    final isGood = enableIncomes ? isIncrease : !isIncrease;
    final filledPrimary = AppContrast.primaryWithWhiteText(
      theme.colorScheme.primary,
      minimumRatio: widget.integrated ? 7 : 4.5,
    );
    final badgeTextColor = AppContrast.accentOnSurface(
      isGood ? Colors.greenAccent[400]! : Colors.redAccent[200]!,
      filledPrimary,
      isDark: true,
    );
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final comparison = hasPreviousMonths
        ? Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.integrated
                      ? Colors.black.withValues(alpha: 0.12)
                      : badgeTextColor.withAlpha((255 * 0.15).round()),
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
                      ? 'vs. média até o mesmo dia'
                      : 'vs. média de gastos até o mesmo dia',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cardTextColor.withAlpha((255 * 0.88).round()),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          )
        : Text(
            'Sem histórico anterior para comparação',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cardTextColor.withAlpha((255 * 0.88).round()),
              fontSize: 12,
            ),
          );

    final valueSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [comparison],
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final primaryHue = HSLColor.fromColor(theme.colorScheme.primary).hue;
        final isGreenish = primaryHue >= 70 && primaryHue <= 160;
        final isReddish = primaryHue >= 330 || primaryHue <= 20;
        final incomeIconColor = isGreenish
            ? cardTextColor
            : AppContrast.accentOnSurface(
                Colors.greenAccent[400]!,
                filledPrimary,
                isDark: true,
              );
        final expenseIconColor = isReddish
            ? cardTextColor
            : AppContrast.accentOnSurface(
                theme.colorScheme.error,
                filledPrimary,
                isDark: true,
              );
        if (widget.integrated) {
          return _IntegratedSummary(
            backgroundColor: filledPrimary,
            title: enableIncomes ? 'Saldo realizado' : 'Despesas do mês',
            amount: _animation.value,
            comparison: comparison,
            income: enableIncomes ? viewModel.realizedIncomeForMonth : null,
            expenses: viewModel.realizedAmountForMonth,
            onOpen: () => ref
                .read(navigationViewModelProvider)
                .navigateTo(AppDestination.expenses),
          );
        }
        return BalanceCard(
          integrated: widget.integrated,
          title: enableIncomes ? 'Saldo realizado' : 'Despesas do mês',
          totalValue: _animation.value,
          foregroundColor: cardTextColor,
          backgroundColor: filledPrimary,
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
                          Flexible(
                            child: Text(
                              'Receitas: ${currencyFormatter.format(viewModel.realizedIncomeForMonth)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cardTextColor,
                                fontWeight: FontWeight.w600,
                              ),
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
                          Flexible(
                            child: Text(
                              'Despesas: ${currencyFormatter.format(viewModel.realizedAmountForMonth)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cardTextColor,
                                fontWeight: FontWeight.w600,
                              ),
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

/// A continuous themed header with readable amounts and responsive metrics.
/// The background matches the app bar, then deepens toward the lower edge.
class _IntegratedSummary extends StatelessWidget {
  const _IntegratedSummary({
    required this.backgroundColor,
    required this.title,
    required this.amount,
    required this.comparison,
    required this.income,
    required this.expenses,
    required this.onOpen,
  });

  final Color backgroundColor;
  final String title;
  final double amount;
  final Widget comparison;
  final double? income;
  final double expenses;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    Widget metric(String label, double value, IconData icon) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  money.format(value),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundColor,
            Color.lerp(backgroundColor, Colors.black, 0.1)!,
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      DateFormat('MMMM yyyy', 'pt_BR').format(DateTime.now()),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                label: 'Ver lançamentos. $title: ${money.format(amount)}',
                onTap: onOpen,
                excludeSemantics: true,
                child: InkWell(
                  onTap: onOpen,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                money.format(amount),
                                maxLines: 1,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 40,
                                  letterSpacing: -1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              comparison,
              if (income != null) ...[
                const SizedBox(height: 20),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final items = [
                      metric('Receitas', income!, Icons.south_west_rounded),
                      metric('Despesas', expenses, Icons.north_east_rounded),
                    ];
                    if (MediaQuery.textScalerOf(context).scale(16) > 22 &&
                        constraints.maxWidth < 400) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          items[0],
                          const SizedBox(height: 16),
                          items[1],
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: items[0]),
                        const SizedBox(width: 24),
                        Expanded(child: items[1]),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
