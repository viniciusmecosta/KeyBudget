import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/utils/date_utils.dart';
import 'package:key_budget/features/analysis/view/analysis_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/view/expense_detail_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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

  String _getRelativeDate(DateTime date) {
    return DateUtils.getRelativeDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DashboardViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);
    final user = authViewModel.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bem-vindo(a) de volta,',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            Text(
              user?.name ?? 'Usuário',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: viewModel.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Carregando seus dados...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
              )
            : RefreshIndicator(
                onRefresh: _fetchInitialData,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(AppTheme.defaultPadding),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildTotalBalanceCard(context, viewModel)
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 100))
                              .slideY(begin: 0.3, end: 0),
                          const SizedBox(height: AppTheme.spaceL),
                          _buildQuickActionsRow(context, viewModel)
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 200))
                              .slideY(begin: 0.3, end: 0),
                          const SizedBox(height: AppTheme.spaceXL),
                          _buildSectionHeader(context, 'Atividades Recentes')
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 300))
                              .slideX(begin: -0.2, end: 0),
                          const SizedBox(height: AppTheme.spaceM),
                          _buildRecentActivitySection(context, viewModel)
                              .animate()
                              .fadeIn(
                                  duration: const Duration(milliseconds: 400),
                                  delay: const Duration(milliseconds: 400))
                              .slideY(begin: 0.2, end: 0),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(
      BuildContext context, DashboardViewModel viewModel) {
    final theme = Theme.of(context);
    final percentageChange = viewModel.percentageChangeFromAverage;
    final hasPreviousMonths = viewModel.averageOfPreviousMonths > 0;

    final isIncrease = percentageChange >= 0;
    final formattedPercentage =
        '${isIncrease ? '+' : '-'}${percentageChange.abs().toStringAsFixed(1)}%';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Provider.of<NavigationViewModel>(context, listen: false)
                .selectedIndex = 1;
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                            ),
                          ),
                          const SizedBox(height: AppTheme.spaceS),
                          Text(
                            _currencyFormatter
                                .format(viewModel.totalAmountForMonth),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                if (hasPreviousMonths) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isIncrease ? Icons.trending_up : Icons.trending_down,
                          color: theme.colorScheme.onPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedPercentage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'vs média',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
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

  Widget _buildQuickActionsRow(
      BuildContext context, DashboardViewModel viewModel) {
    final navigationViewModel =
        Provider.of<NavigationViewModel>(context, listen: false);

    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            title: 'Credenciais',
            subtitle: '${viewModel.credentialCount} cadastradas',
            icon: Icons.security_rounded,
            color: Theme.of(context).colorScheme.secondary,
            onTap: () => navigationViewModel.selectedIndex = 2,
          ),
        ),
        const SizedBox(width: AppTheme.spaceM),
        Expanded(
          child: _buildQuickActionCard(
            context,
            title: 'Análise',
            subtitle: 'Ver relatórios',
            icon: Icons.bar_chart_rounded,
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AnalysisScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        TextButton(
          onPressed: () {
            Provider.of<NavigationViewModel>(context, listen: false)
                .selectedIndex = 1;
          },
          child: Text(
            'Ver todas',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(
      BuildContext context, DashboardViewModel viewModel) {
    final recentExpenses = viewModel.recentExpenses;

    if (viewModel.isLoading) {
      return const SizedBox.shrink();
    }

    if (recentExpenses.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: recentExpenses
          .asMap()
          .entries
          .map((entry) => _buildActivityTile(context, entry.value, entry.key))
          .toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spaceM),
          Text(
            'Nenhuma atividade recente',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            'Suas transações aparecerão aqui assim que forem registradas',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(BuildContext context, Expense expense, int index) {
    final theme = Theme.of(context);
    final category = Provider.of<CategoryViewModel>(context, listen: false)
        .getCategoryById(expense.categoryId);

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ExpenseDetailScreen(expense: expense),
            ));
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (category?.color ?? theme.colorScheme.primary)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    category?.icon ?? Icons.shopping_bag_rounded,
                    color: category?.color ?? theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.location?.isNotEmpty == true
                            ? expense.location!
                            : (category?.name ?? 'Gasto Geral'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRelativeDate(expense.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '- ${_currencyFormatter.format(expense.amount)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideX(begin: 0.2, end: 0);
  }
}
