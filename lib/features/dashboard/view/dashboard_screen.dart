import 'package:flutter/material.dart' hide DateUtils;
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../../app/config/app_theme.dart';
import '../widgets/dashboard_balance_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_activity_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null && mounted) {
        final userId = authViewModel.currentUser!.id;

        await Provider.of<CategoryViewModel>(context, listen: false)
            .fetchCategories(userId);
        if (!mounted) return;
        Provider.of<ExpenseViewModel>(context, listen: false)
            .listenToExpenses(userId);
        if (!mounted) return;
        Provider.of<CredentialViewModel>(context, listen: false)
            .listenToCredentials(userId);
      }
    } finally {
      if (mounted && isRefresh) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DashboardViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const DashboardHeader(),
      body: SafeArea(
        child: viewModel.isLoading
            ? const DashboardSkeleton()
            : RefreshIndicator(
                onRefresh: _fetchInitialData,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                strokeWidth: 2.5,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppTheme.spaceM,
                          AppTheme.spaceS, AppTheme.spaceM, AppTheme.spaceL),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          AppAnimations.fadeInFromBottom(
                              const DashboardBalanceCard()),
                          const SizedBox(height: AppTheme.spaceL),
                          AppAnimations.fadeInFromBottom(
                              const QuickActionsSection(),
                              delay: const Duration(milliseconds: 100)),
                          const SizedBox(height: AppTheme.spaceXL),
                          AppAnimations.fadeInFromBottom(
                              const RecentActivitySection(),
                              delay: const Duration(milliseconds: 200)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
