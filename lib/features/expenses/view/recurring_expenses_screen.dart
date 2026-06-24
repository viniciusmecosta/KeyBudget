import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/app/widgets/empty_state_widget.dart';
import 'package:key_budget/features/expenses/view/add_edit_recurring_expense_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/expenses/widgets/recurring_expense_list_tile.dart';

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(expenseViewModelProvider);
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
              ? const EmptyStateWidget(
                  icon: Icons.replay_circle_filled_outlined,
                  message: 'Nenhuma despesa recorrente encontrada.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
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
        label: const Text('Nova Despesa'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
