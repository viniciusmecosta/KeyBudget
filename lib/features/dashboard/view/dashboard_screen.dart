import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/dashboard_balance_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/recent_activity_section.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    _refreshController.forward();

    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null && mounted) {
        final userId = authViewModel.currentUser!.id;

        await Provider.of<CategoryViewModel>(context, listen: false)
            .fetchCategories(userId);

        Provider.of<ExpenseViewModel>(context, listen: false)
            .listenToExpenses(userId);

        Provider.of<CredentialViewModel>(context, listen: false)
            .listenToCredentials(userId);
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _refreshController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DashboardViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const DashboardHeader(),
      body: SafeArea(
        child: viewModel.isLoading
            ? _buildLoadingState(theme)
            : RefreshIndicator(
                onRefresh: _fetchInitialData,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                strokeWidth: 2.5,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppTheme.spaceM,
                          AppTheme.spaceS, AppTheme.spaceM, AppTheme.spaceL),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const DashboardBalanceCard()
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 100.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: AppTheme.spaceL),
                          const QuickActionsSection()
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
                          const SizedBox(height: AppTheme.spaceXL),
                          const RecentActivitySection()
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 300.ms)
                              .slideX(begin: -0.1, end: 0),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: AppTheme.spaceL),
          Text(
            'Carregando seus dados...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
