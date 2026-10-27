import 'package:passfin/app/utils/navigation_utils.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/app/widgets/empty_state_widget.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';
import 'package:passfin/features/expenses/view/add_edit_recurring_expense_screen.dart';
import 'package:passfin/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:passfin/features/expenses/widgets/recurring_expense_list_tile.dart';

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(expenseViewModelProvider);
    final theme = Theme.of(context);

    return AppPageScaffold(
      appBar: AppBar(title: const Text('Despesas Recorrentes')),
      body: viewModel.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
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
        onPressed: () => NavigationUtils.push(
          context,
          const AddEditRecurringExpenseScreen(),
        ),
        label: const Text('Nova Despesa'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
