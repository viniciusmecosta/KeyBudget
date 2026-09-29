import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
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

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final expenseViewModel = ref.watch(expenseViewModelProvider);
    final theme = Theme.of(context);

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
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: ExpenseSyncIndicator(
                            status: expenseViewModel.syncStatus,
                            lastServerConfirmation: expenseViewModel.lastServerConfirmation,
                            onRetry: () {
                              final userId = ref.read(authViewModelProvider).currentUser?.id;
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
                              final isExpanded = constraints.maxWidth >= 840;
                              if (isExpanded) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        children: [
                                          AppAnimations.fadeInFromBottom(
                                            const DashboardBalanceCard(),
                                            key: const Key('dashboard_balance'),

                                            context: context,),
                                          const SizedBox(height: AppSpacing.md),
                                          AppAnimations.fadeInFromBottom(
                                            const QuickActionsSection(),
                                            key: const Key('dashboard_quick_actions'),
                                            delay: const Duration(milliseconds: 100),

                                            context: context,),
                                          const SizedBox(height: AppSpacing.md),
                                          AppAnimations.fadeInFromBottom(
                                            const DashboardMonthlyChart(),
                                            key: const Key('dashboard_chart'),
                                            delay: const Duration(milliseconds: 200),

                                            context: context,),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.lg),
                                    Expanded(
                                      flex: 5,
                                      child: AppAnimations.fadeInFromBottom(
                                        const RecentActivitySection(),
                                        key: const Key('dashboard_recent_activity'),
                                        delay: const Duration(milliseconds: 150),

                                        context: context,),
                                    ),
                                  ],
                                );
                              }

                              return Column(
                                children: [
                                  AppAnimations.fadeInFromBottom(
                                    const DashboardBalanceCard(),
                                    key: const Key('dashboard_balance'),

                                    context: context,),
                                  const SizedBox(height: AppSpacing.md),
                                  AppAnimations.fadeInFromBottom(
                                    const DashboardMonthlyChart(),
                                    key: const Key('dashboard_chart'),
                                    delay: const Duration(milliseconds: 100),

                                    context: context,),
                                  const SizedBox(height: AppSpacing.md),
                                  AppAnimations.fadeInFromBottom(
                                    const QuickActionsSection(),
                                    key: const Key('dashboard_quick_actions'),
                                    delay: const Duration(milliseconds: 200),

                                    context: context,),
                                  const SizedBox(height: AppSpacing.md),
                                  AppAnimations.fadeInFromBottom(
                                    const RecentActivitySection(),
                                    key: const Key('dashboard_recent_activity'),
                                    delay: const Duration(milliseconds: 300),

                                    context: context,),
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
