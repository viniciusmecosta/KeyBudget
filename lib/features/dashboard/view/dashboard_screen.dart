import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/repository/dashboard_layout_repository.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/expenses/widgets/expense_sync_indicator.dart';

import '../widgets/dashboard_balance_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_monthly_chart.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_activity_section.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData(isRefresh: false);
    });
  }

  Future<void> _fetchInitialData({bool isRefresh = true}) async {
    final authViewModel = ref.read(authViewModelProvider);
    final userId = authViewModel.currentUser?.id;
    if (userId == null) return;

    if (!mounted) return;
    if (!isRefresh) {
      if (_isRefreshing) return;
      setState(() => _isRefreshing = true);
    } else {
      ref.read(dashboardViewModelProvider).triggerRefresh();
      setState(() => _isRefreshing = true);
    }

    try {
      if (authViewModel.currentUser != null && mounted) {
        await ref.read(categoryViewModelProvider).fetchCategories(userId);
        if (!mounted) return;
        ref.read(expenseViewModelProvider).listenToExpenses(userId);
        if (!mounted) return;
        ref.read(credentialViewModelProvider).listenToCredentials(userId);
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Widget _cardFor(String id, List<String> actions) {
    switch (id) {
      case 'balance':
        return const DashboardBalanceCard();
      case 'chart':
        return const DashboardMonthlyChart();
      case 'quick_actions':
        return QuickActionsSection(actionIds: actions);
      default:
        return const RecentActivitySection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final expenseViewModel = ref.watch(expenseViewModelProvider);
    final theme = Theme.of(context);
    final userId = ref.watch(authViewModelProvider).currentUser?.id;
    final layout = userId == null
        ? const DashboardLayout()
        : ref.watch(dashboardLayoutProvider(userId)).asData?.value ??
              const DashboardLayout();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const DashboardHeader(),
      body: SafeArea(
        child: viewModel.isLoading
            ? const ResponsiveCenter(maxWidth: 1200, child: DashboardSkeleton())
            : RefreshIndicator(
                onRefresh: _fetchInitialData,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                strokeWidth: 2.5,
                child: ResponsiveCenter(
                  maxWidth: 1200,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: ExpenseSyncIndicator(
                            status: expenseViewModel.syncStatus,
                            onRetry: () {
                              final userId = ref
                                  .read(authViewModelProvider)
                                  .currentUser
                                  ?.id;
                              if (userId != null) {
                                expenseViewModel.retryListenToExpenses(userId);
                              }
                            },
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final expanded = constraints.maxWidth >= 840;
                              final width = expanded
                                  ? (constraints.maxWidth - AppSpacing.lg) / 2
                                  : constraints.maxWidth;
                              return Wrap(
                                spacing: AppSpacing.lg,
                                runSpacing: AppSpacing.md,
                                children: [
                                  for (
                                    var index = 0;
                                    index < layout.cards.length;
                                    index++
                                  )
                                    SizedBox(
                                      key: ValueKey(
                                        'dashboard_${layout.cards[index]}',
                                      ),
                                      width: width,
                                      child: AppAnimations.fadeInFromBottom(
                                        _cardFor(
                                          layout.cards[index],
                                          layout.actions,
                                        ),
                                        context: context,
                                        delay: Duration(
                                          milliseconds: index * 100,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
