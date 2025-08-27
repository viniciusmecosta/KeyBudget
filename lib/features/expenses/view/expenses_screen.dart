import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        Provider.of<CategoryViewModel>(context, listen: false)
            .fetchCategories(authViewModel.currentUser!.id);
        Provider.of<ExpenseViewModel>(context, listen: false)
            .fetchExpenses(authViewModel.currentUser!.id);
      }
    });
  }

  Future<void> _handleRefresh() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    if (mounted && authViewModel.currentUser != null) {
      await Provider.of<ExpenseViewModel>(context, listen: false)
          .fetchExpenses(authViewModel.currentUser!.id);
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
    final expenseViewModel = Provider.of<ExpenseViewModel>(context, listen: false);
    final categoryViewModel = Provider.of<CategoryViewModel>(context, listen: false);
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
                      final isSelected =
                      expenseViewModel.selectedCategoryIds.contains(category.id);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalValue = context.select<ExpenseViewModel, double>((viewModel) =>
        viewModel.filteredExpenses
            .where((exp) =>
        exp.date.year == _selectedMonth.year &&
            exp.date.month == _selectedMonth.month)
            .fold<double>(0.0, (sum, exp) => sum + exp.amount));
    final categoryViewModel = context.watch<CategoryViewModel>();

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
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Column(
          children: [
            _buildMonthSelector(context),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shadowColor: theme.primaryColor.withOpacity(0.2),
              child: Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.primaryColor.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total do mês',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withOpacity(0.8)),
                    ),
                    Text(
                      _currencyFormatter.format(totalValue),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: theme.colorScheme.onPrimary),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.3),
            Expanded(
              child: Selector<ExpenseViewModel, List<Expense>>(
                selector: (_, vm) => vm.filteredExpenses
                    .where((exp) =>
                exp.date.year == _selectedMonth.year &&
                    exp.date.month == _selectedMonth.month)
                    .toList()
                  ..sort((a, b) => b.date.compareTo(a.date)),
                builder: (context, monthlyExpenses, child) {
                  final isLoading = context
                      .select<ExpenseViewModel, bool>((vm) => vm.isLoading);

                  if (isLoading || categoryViewModel.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (monthlyExpenses.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.money_off,
                      message: 'Nenhuma despesa encontrada para este mês.',
                      buttonText: 'Adicionar Despesa',
                      onButtonPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AddExpenseScreen()),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: monthlyExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = monthlyExpenses[index];
                      final category = categoryViewModel.getCategoryById(expense.categoryId);
                      final formattedDate =
                      DateFormat('d, EEEE', 'pt_BR').format(expense.date);
                      final parts = formattedDate.split(',');
                      final dayOfWeekPart =
                      parts.length > 1 ? parts[1].trim() : '';
                      final displayDate = dayOfWeekPart.isNotEmpty
                          ? '${parts[0]}, ${dayOfWeekPart[0].toUpperCase()}${dayOfWeekPart.substring(1)}'
                          : formattedDate;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                            (category?.color ?? theme.primaryColor).withOpacity(0.15),
                            child: Icon(
                              category?.icon ?? Icons.category,
                              color: category?.color ?? theme.primaryColor,
                            ),
                          ),
                          title: Text(
                            expense.location?.isNotEmpty == true
                                ? expense.location!
                                : (category?.name ?? 'Gasto Geral'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(displayDate),
                          trailing: Text(
                            '- ${_currencyFormatter.format(expense.amount)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ExpenseDetailScreen(expense: expense),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        icon: const Icon(Icons.add),
        label: const Text("Nova Despesa"),
      ).animate().scale(duration: 250.ms),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
}