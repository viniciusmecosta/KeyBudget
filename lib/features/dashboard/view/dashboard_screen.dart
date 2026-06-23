import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/widgets/responsive_center.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

import 'package:key_budget/core/design_system/spacing/app_spacing.dart';

import '../widgets/dashboard_balance_card.dart';
import '../widgets/dashboard_header.dart';
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
    if (_isRefreshing) return;

    if (isRefresh) {
      setState(() => _isRefreshing = true);
    }

    try {
      final authViewModel = ref.read(authViewModelProvider);
      if (authViewModel.currentUser != null && mounted) {
        final userId = authViewModel.currentUser!.id;

        await ref.read(categoryViewModelProvider).fetchCategories(userId);
        if (!mounted) return;
        ref.read(expenseViewModelProvider).listenToExpenses(userId);
        if (!mounted) return;
        ref.read(credentialViewModelProvider).listenToCredentials(userId);
      }
    } finally {
      if (mounted && isRefresh) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(dashboardViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const DashboardHeader(),
      body: SafeArea(
        child: viewModel.isLoading
            ? const ResponsiveCenter(child: DashboardSkeleton())
            : RefreshIndicator(
                onRefresh: _fetchInitialData,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                strokeWidth: 2.5,
                child: ResponsiveCenter(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              AppAnimations.fadeInFromBottom(
                                const DashboardBalanceCard(),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AppAnimations.fadeInFromBottom(
                                const QuickActionsSection(),
                                delay: const Duration(milliseconds: 100),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AppAnimations.fadeInFromBottom(
                                const RecentActivitySection(),
                                delay: const Duration(milliseconds: 200),
                              ),
                            ],
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
