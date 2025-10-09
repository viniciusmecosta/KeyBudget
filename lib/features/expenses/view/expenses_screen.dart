import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/balance_card.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';
import 'package:key_budget/features/expenses/view/export_expenses_screen.dart';
import 'package:key_budget/features/expenses/view/recurring_expenses_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/category_filter_modal.dart';
import '../widgets/expense_list.dart';
import '../widgets/month_selector.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        Provider.of<CategoryViewModel>(context, listen: false)
            .fetchCategories(authViewModel.currentUser!.id);
        Provider.of<ExpenseViewModel>(context, listen: false)
            .listenToExpenses(authViewModel.currentUser!.id);
      }
    });
  }

  Future<void> _handleRefresh() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (mounted && authViewModel.currentUser != null) {
      Provider.of<ExpenseViewModel>(context, listen: false)
          .listenToExpenses(authViewModel.currentUser!.id);
    }
  }

  void _import(BuildContext context) async {
    final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final count =
        await viewModel.importExpensesFromCsv(authViewModel.currentUser!.id);
    if (!mounted) return;
    SnackbarService.showSuccess(
        context, '$count despesas importadas com sucesso!');
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return const CategoryFilterModal();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseViewModel = context.watch<ExpenseViewModel>();
    final categoryViewModel = context.watch<CategoryViewModel>();

    final monthlyExpenses = expenseViewModel.filteredExpenses
        .where((exp) =>
            exp.date.year == _selectedMonth.year &&
            exp.date.month == _selectedMonth.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalValue =
        monthlyExpenses.fold<double>(0.0, (sum, exp) => sum + exp.amount);

    Widget body = RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      strokeWidth: 2.5,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                MonthSelector(
                  selectedMonth: _selectedMonth,
                  onMonthChanged: (newMonth) {
                    setState(() {
                      _selectedMonth = newMonth;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.defaultPadding),
                  child: BalanceCard(
                    title: 'Total do mês',
                    totalValue: totalValue,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),
                ),
                const SizedBox(height: AppTheme.spaceL),
              ],
            ),
          ),
          if (monthlyExpenses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Icons.money_off_rounded,
                message: 'Nenhuma despesa encontrada para este mês.',
                buttonText: 'Adicionar Despesa',
                onButtonPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                ),
              ),
            )
          else
            ExpenseList(
              monthlyExpenses: monthlyExpenses,
              isFirstLoad: _isFirstLoad,
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Despesas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: _showCategoryFilter,
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: theme.colorScheme.onSurface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recurring',
                child: Row(
                  children: [
                    Icon(Icons.replay_circle_filled_rounded),
                    SizedBox(width: AppTheme.spaceS),
                    Text('Despesas Recorrentes'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    const Text('Importar de CSV'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(
                      Icons.download_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppTheme.spaceS),
                    const Text('Exportar para CSV'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'import') _import(context);
              if (value == 'export') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ExportExpensesScreen()),
                );
              }
              if (value == 'recurring') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const RecurringExpensesScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: expenseViewModel.isLoading || categoryViewModel.isLoading
            ? _buildLoadingState(theme)
            : body.animate(
                onComplete: (_) {
                  if (_isFirstLoad && mounted) {
                    setState(() => _isFirstLoad = false);
                  }
                },
              ).fadeIn(duration: 250.ms),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_expenses',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Nova Despesa"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
      ).animate().scale(duration: 250.ms),
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
            'Carregando suas despesas...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha((255 * 0.7).round()),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
