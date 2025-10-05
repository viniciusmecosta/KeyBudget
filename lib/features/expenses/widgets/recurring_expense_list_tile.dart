import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_edit_recurring_expense_screen.dart';
import 'package:provider/provider.dart';

class RecurringExpenseListTile extends StatelessWidget {
  final RecurringExpense expense;

  const RecurringExpenseListTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category =
        context.read<CategoryViewModel>().getCategoryById(expense.categoryId);
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category?.color ?? theme.colorScheme.primary,
          child: Icon(
            category?.icon ?? Icons.category,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        title: Text(
          expense.motivation ?? expense.location ?? category?.name ?? 'Despesa',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
            '${currencyFormatter.format(expense.amount)} - ${expense.frequency.name}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditRecurringExpenseScreen(expense: expense),
            ),
          );
        },
      ),
    );
  }
}
