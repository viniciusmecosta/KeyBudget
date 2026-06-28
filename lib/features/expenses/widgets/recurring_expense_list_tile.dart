import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/view/add_edit_recurring_expense_screen.dart';

class RecurringExpenseListTile extends ConsumerWidget {
  final RecurringExpense expense;

  const RecurringExpenseListTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final category =
        ref.read(categoryViewModelProvider).getCategoryById(expense.categoryId);
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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: AppBorders.borderRadiusL,
        elevation: 0,
        child: InkWell(
          onTap: () {
            NavigationUtils.push(
                context, AddEditRecurringExpenseScreen(expense: expense));
          },
          borderRadius: AppBorders.borderRadiusL,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppBorders.borderRadiusL,
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
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        expense.location ??
                            expense.motivation ??
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
                const SizedBox(width: AppSpacing.sm),
                Text(
                  currencyFormatter.format(expense.amount),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
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
