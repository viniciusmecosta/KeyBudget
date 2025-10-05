import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/features/expenses/view/add_edit_recurring_expense_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/expenses/widgets/recurring_expense_list_tile.dart';
import 'package:provider/provider.dart';

class RecurringExpensesScreen extends StatelessWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ExpenseViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despesas Recorrentes'),
      ),
      body: viewModel.isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ))
          : viewModel.recurringExpenses.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.replay_circle_filled_outlined,
                  message: 'Nenhuma despesa recorrente encontrada.',
                  buttonText: 'Adicionar Recorrente',
                  onButtonPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AddEditRecurringExpenseScreen(),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.defaultPadding),
                  itemCount: viewModel.recurringExpenses.length,
                  itemBuilder: (context, index) {
                    final recurring = viewModel.recurringExpenses[index];
                    return RecurringExpenseListTile(expense: recurring);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AddEditRecurringExpenseScreen(),
          ),
        ),
        label: const Text('Adicionar'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
