import 'package:flutter/material.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.currentUser != null) {
        Provider.of<ExpenseViewModel>(context, listen: false)
            .fetchExpenses(authViewModel.currentUser!.id!);
      }
    });
  }

  void _import(BuildContext context) async {
    final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final count =
        await viewModel.importExpensesFromCsv(authViewModel.currentUser!.id!);
    scaffoldMessenger.showSnackBar(SnackBar(
        content: Text('$count despesas importadas com sucesso!'),
        backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Gastos'),
        actions: [
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
      body: Consumer<ExpenseViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.expenses.isEmpty) {
            return const Center(
              child: Text('Nenhuma despesa cadastrada.'),
            );
          }
          return ListView.builder(
            itemCount: viewModel.expenses.length,
            itemBuilder: (context, index) {
              final expense = viewModel.expenses[index];
              return ListTile(
                title: Text(expense.motivation ?? 'Gasto Geral'),
                subtitle: Text(
                    '${expense.date.day}/${expense.date.month}/${expense.date.year}'),
                trailing: Text(
                  'R\$ ${expense.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExpenseDetailScreen(expense: expense),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
