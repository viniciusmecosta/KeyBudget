import 'package:auto_size_text/auto_size_text.dart';
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
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final category =
        context.read<CategoryViewModel>().getCategoryById(expense.categoryId);
    final categoryColor = category?.color ?? colorScheme.primary;

    String recurrenceInfo;
    switch (expense.frequency) {
      case RecurrenceFrequency.daily:
        recurrenceInfo = 'Diariamente';
        break;
      case RecurrenceFrequency.weekly:
        recurrenceInfo = 'Semanalmente';
        break;
      case RecurrenceFrequency.monthly:
        recurrenceInfo = 'Todo dia ${expense.dayOfMonth}';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddEditRecurringExpenseScreen(expense: expense),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      categoryColor.withAlpha((255 * 0.15).round()),
                  child: Icon(category?.icon ?? Icons.category,
                      color: categoryColor, size: 24),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        expense.motivation ??
                            expense.location ??
                            category?.name ??
                            'Despesa Recorrente',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        minFontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.replay_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant
                                  .withAlpha((255 * 0.7).round())),
                          const SizedBox(width: 4),
                          Text(
                            recurrenceInfo,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant
                                  .withAlpha((255 * 0.8).round()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spaceS),
                Text(
                  currencyFormatter.format(expense.amount),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
