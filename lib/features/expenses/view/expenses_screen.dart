import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';
import 'package:key_budget/features/expenses/view/export_expenses_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../../app/widgets/activity_tile_widget.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    final count =
        await viewModel.importExpensesFromCsv(authViewModel.currentUser!.id);
    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('$count despesas importadas com sucesso!'),
        backgroundColor: theme.colorScheme.secondaryContainer,
      ),
    );
  }

  void _showCategoryFilter() {
    final expenseViewModel =
        Provider.of<ExpenseViewModel>(context, listen: false);
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXL)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(AppTheme.spaceL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    width: 48,
                    margin: const EdgeInsets.only(bottom: AppTheme.spaceL),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                  ),
                  Text(
                    'Filtrar por Categoria',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: categoryViewModel.categories.map((category) {
                        final isSelected = expenseViewModel.selectedCategoryIds
                            .contains(category.id);
                        return Container(
                          margin:
                              const EdgeInsets.only(bottom: AppTheme.spaceXS),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary.withOpacity(0.2)
                                  : theme.colorScheme.outline.withOpacity(0.1),
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              category.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                            value: isSelected,
                            activeColor: theme.colorScheme.primary,
                            onChanged: (value) {
                              final currentSelection = List<String>.from(
                                  expenseViewModel.selectedCategoryIds);
                              if (value == true) {
                                currentSelection.add(category.id!);
                              } else {
                                currentSelection.remove(category.id);
                              }
                              expenseViewModel
                                  .setCategoryFilter(currentSelection);
                              setModalState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceL),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        expenseViewModel.clearFilters();
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spaceM),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                      ),
                      child: const Text('Limpar Filtros'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatMonthYear(DateTime date) {
    final now = DateTime.now();
    String formattedDate;

    if (date.year == now.year) {
      formattedDate = DateFormat.MMMM('pt_BR').format(date);
    } else {
      formattedDate = DateFormat.yMMMM('pt_BR').format(date);
    }
    return formattedDate.isNotEmpty
        ? formattedDate[0].toUpperCase() + formattedDate.substring(1)
        : '';
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
                _buildMonthSelector(context),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.defaultPadding),
                  child: _buildTotalBalanceCard(context, totalValue),
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.defaultPadding, 0, AppTheme.defaultPadding, 96.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = monthlyExpenses[index];
                    return _buildExpenseTile(expense, index);
                  },
                  childCount: monthlyExpenses.length,
                ),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.defaultPadding, vertical: AppTheme.spaceS),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceS, vertical: AppTheme.spaceXS),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            _formatMonthYear(_selectedMonth),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
            style: IconButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, double totalValue) {
    final theme = Theme.of(context);
    Widget card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total do mês',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceS),
                Text(
                  _currencyFormatter.format(totalValue),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: theme.colorScheme.onPrimary,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );

    if (_isFirstLoad) {
      return card.animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, end: 0);
    }
    return card;
  }

  Widget _buildExpenseTile(Expense expense, int index) {
    Widget tile = ActivityTile(
      expense: expense,
      index: index,
    );

    if (_isFirstLoad) {
      return tile
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
    }

    return tile;
  }
}
