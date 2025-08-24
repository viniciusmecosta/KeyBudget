import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/core/models/expense_category.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';
import 'package:key_budget/features/expenses/view/expense_detail_screen.dart';
import 'package:key_budget/features/expenses/view/export_expenses_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

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
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('$count despesas importadas com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCategoryFilter() {
    final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);
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
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Filtrar por Categoria',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Expanded(
                  child: ListView(
                    children: ExpenseCategory.values.map((category) {
                      final isSelected =
                      viewModel.selectedCategories.contains(category);
                      return CheckboxListTile(
                        title: Text(category.displayName),
                        value: isSelected,
                        onChanged: (value) {
                          final currentSelection = List<ExpenseCategory>.from(
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
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalValue = monthlyExpenses.fold<double>(
      0.0,
          (sum, exp) => sum + exp.amount,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Gastos'),
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
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Total do mês',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'R\$ ${totalValue.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
            Expanded(
              child: Consumer<ExpenseViewModel>(
                builder: (context, vm, child) {
                  if (vm.isLoading) {
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: monthlyExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = monthlyExpenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15),
                            child: Icon(
                              expense.category?.icon ?? Icons.category,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            expense.location?.isNotEmpty == true
                                ? expense.location!
                                : (expense.category?.displayName ??
                                'Gasto Geral'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            DateFormat('dd/MM/yyyy').format(expense.date),
                          ),
                          trailing: Text(
                            'R\$ ${expense.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 18,
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
                      )
                          .animate()
                          .fadeIn(delay: (50 * index).ms, duration: 300.ms)
                          .slideX(begin: 0.1, end: 0);
                    },
                  );
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
      )
          .animate()
          .scaleXY(begin: 0.9, end: 1.0, duration: 200.ms)
          .then(delay: 1000.ms)
          .scaleXY(end: 1.05, duration: 600.ms)
          .then()
          .scaleXY(end: 1.0, duration: 600.ms),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
