import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/app/widgets/balance_card.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

import '../widgets/category_filter_modal.dart';
import '../widgets/expense_actions_popup_menu.dart';
import '../widgets/expense_list.dart';
import '../widgets/expenses_list_skeleton.dart';
import '../widgets/month_selector.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
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

    final bool isLoading =
        (expenseViewModel.isLoading || categoryViewModel.isLoading) &&
            _isFirstLoad;

    Widget body = RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      strokeWidth: 2.5,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate(
              [
                MonthSelector(
                  selectedMonth: expenseViewModel.selectedMonth,
                  onMonthChanged: (newMonth) {
                    expenseViewModel.setSelectedMonth(newMonth);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.defaultPadding),
                  child: AppAnimations.fadeIn(BalanceCard(
                    title: 'Total do mês',
                    totalValue: expenseViewModel.currentMonthTotal,
                  )),
                ),
                const SizedBox(height: AppTheme.spaceL),
              ],
            ),
          ),
          if (isLoading)
            const ExpensesListSkeleton()
          else if (expenseViewModel.monthlyFilteredExpenses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                icon: Icons.money_off_rounded,
                message: 'Nenhuma despesa encontrada para este mês.',
                buttonText: 'Adicionar Despesa',
                onButtonPressed: () =>
                    NavigationUtils.push(context, const AddExpenseScreen()),
              ),
            )
          else
            ExpenseList(
              monthlyExpenses: expenseViewModel.monthlyFilteredExpenses,
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
          const ExpenseActionsPopupMenu(),
        ],
      ),
      body: SafeArea(
        child: body.animate(onComplete: (controller) {
          if (_isFirstLoad) {
            setState(() {
              _isFirstLoad = false;
            });
          }
        }).fadeIn(duration: 300.ms),
      ),
      floatingActionButton: AppAnimations.scaleIn(FloatingActionButton.extended(
        heroTag: 'fab_expenses',
        onPressed: () =>
            NavigationUtils.push(context, const AddExpenseScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Nova Despesa"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
      )),
    );
  }
}
