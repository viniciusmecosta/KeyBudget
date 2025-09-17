import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/utils/date_utils.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';
import 'package:key_budget/features/expenses/view/expense_detail_screen.dart';
import 'package:key_budget/features/expenses/view/export_expenses_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  final _currencyFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filtrar por Categoria',
                  style: theme.textTheme.titleLarge,
                ),
                Expanded(
                  child: ListView(
                    children: categoryViewModel.categories.map((category) {
                      final isSelected = expenseViewModel.selectedCategoryIds
                          .contains(category.id);
                      return CheckboxListTile(
                        title: Text(category.name),
                        value: isSelected,
                        onChanged: (value) {
                          final currentSelection = List<String>.from(
                              expenseViewModel.selectedCategoryIds);
                          if (value == true) {
                            currentSelection.add(category.id!);
                          } else {
                            currentSelection.remove(category.id);
                          }
                          expenseViewModel.setCategoryFilter(currentSelection);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: () {
                      expenseViewModel.clearFilters();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Limpar Filtros'),
                  ),
                )
              ],
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

  String _getRelativeDate(DateTime date) {
    return DateUtils.getRelativeDate(date);
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
              child: EmptyStateWidget(
                icon: Icons.money_off,
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
                    return _buildActivityTile(context, expense, index);
                  },
                  childCount: monthlyExpenses.length,
                ),
              ),
            ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showCategoryFilter,
          ),
          PopupMenuButton(
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'import', child: Text('Importar de CSV')),
              PopupMenuItem(value: 'export', child: Text('Exportar para CSV')),
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
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    Text(
                      'Carregando suas despesas...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
              )
            : body.animate(
                onComplete: (_) {
                  if (_isFirstLoad && mounted) {
                    setState(() => _isFirstLoad = false);
                  }
                },
              ).fadeIn(
                duration: 250.ms,
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_expenses',
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        icon: const Icon(Icons.add),
        label: const Text("Nova Despesa"),
      ).animate().scale(duration: 250.ms),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.defaultPadding, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
          ),
          Text(
            _formatMonthYear(_selectedMonth),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, double totalValue) {
    final theme = Theme.of(context);
    Widget card = Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total do mês',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  fontWeight: FontWeight.bold),
            ),
            Text(
              _currencyFormatter.format(totalValue),
              style: theme.textTheme.headlineMedium
                  ?.copyWith(color: theme.colorScheme.onPrimary),
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

  Widget _buildActivityTile(BuildContext context, Expense expense, int index) {
    final theme = Theme.of(context);
    final category = Provider.of<CategoryViewModel>(context, listen: false)
        .getCategoryById(expense.categoryId);

    Widget tile = Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpenseDetailScreen(expense: expense),
              ),
            );
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
    );

    if (_isFirstLoad) {
      return tile
          .animate(delay: Duration(milliseconds: 200 + (100 * index)))
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.2, end: 0);
    }

    return tile;
  }
}
