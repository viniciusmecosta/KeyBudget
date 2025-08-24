import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/models/expense_category.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
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

    final count =
    await viewModel.importExpensesFromCsv(authViewModel.currentUser!.id);
    if (!mounted) return;
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('$count despesas importadas com sucesso!'),
        backgroundColor: Colors.green));
  }

  void _showCategoryFilter() {
    final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Filtrar por Categoria',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Expanded(
                  child: ListView(
                    children: ExpenseCategory.values.map((category) {
                      final isSelected =
                      viewModel.selectedCategories.contains(category);
                      return CheckboxListTile(
                        title: Text(category.displayName),
                        value: isSelected,
                        onChanged: (bool? value) {
                          var currentSelection = List<ExpenseCategory>.from(
                              viewModel.selectedCategories);
                          if (value == true) {
                            currentSelection.add(category);
                          } else {
                            currentSelection.remove(category);
                          }
                          viewModel.setCategoryFilter(currentSelection);
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
                      viewModel.clearFilters();
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

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ExpenseViewModel>(context);

    final monthlyExpenses = viewModel.filteredExpenses
        .where((exp) =>
    exp.date.year == _selectedMonth.year &&
        exp.date.month == _selectedMonth.month)
        .toList();
    monthlyExpenses.sort((a, b) => b.date.compareTo(a.date));

    final totalValue = monthlyExpenses.fold<double>(
      0.0,
          (sum, exp) => sum + exp.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Gastos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showCategoryFilter,
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'import', child: Text('Importar de CSV')),
              const PopupMenuItem(
                  value: 'export', child: Text('Exportar para CSV')),
            ],
            onSelected: (value) {
              if (value == 'import') _import(context);
              if (value == 'export') {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ExportExpensesScreen()));
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Total: R\$ ${totalValue.toStringAsFixed(2)}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Consumer<ExpenseViewModel>(
                builder: (context, vm, child) {
                  if (vm.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (monthlyExpenses.isEmpty) {
                    return LayoutBuilder(builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                          child: EmptyStateWidget(
                            icon: Icons.money_off,
                            message:
                            'Nenhuma despesa encontrada para este mês.',
                            buttonText: 'Adicionar Despesa',
                            onButtonPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const AddExpenseScreen())),
                          ),
                        ),
                      );
                    });
                  }
                  return ListView.builder(
                    itemCount: monthlyExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = monthlyExpenses[index];
                      return ListTile(
                        leading: Icon(expense.category?.icon ?? Icons.category),
                        title: Text(expense.location?.isNotEmpty == true
                            ? expense.location!
                            : (expense.category?.displayName ?? 'Gasto Geral')),
                        subtitle:
                        Text(DateFormat('dd/MM/yyyy').format(expense.date)),
                        trailing: Text(
                          'R\$ ${expense.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExpenseDetailScreen(expense: expense),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: (20 * index).ms, duration: 100.ms).slideY(begin: 0.1, end: 0);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 100.ms, duration: 150.ms),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
            DateFormat.yMMMM('pt_BR').format(_selectedMonth),
            style: Theme.of(context).textTheme.titleLarge,
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