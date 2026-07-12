import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/utils/date_utils.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/view/expense_detail_screen.dart';

class ActivityTile extends ConsumerWidget {
  final Expense expense;
  final int index;
  final bool showFullDate;

  const ActivityTile({
    super.key,
    required this.expense,
    required this.index,
    this.showFullDate = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currencyFormatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );

    final category = ref
        .read(categoryViewModelProvider)
        .getCategoryById(expense.categoryId);

    final categoryColor = category?.color ?? colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () =>
          NavigationUtils.push(context, ExpenseDetailScreen(expense: expense)),
      child: Row(
        children: [
          _buildCategoryIcon(categoryColor, category),
          const SizedBox(width: AppSpacing.md),
          _buildExpenseInfo(context, textTheme, colorScheme, category),
          const SizedBox(width: AppSpacing.xs),
          _buildAmountInfo(textTheme, currencyFormatter, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(Color categoryColor, dynamic category) {
    if (expense.isIncome == true) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.greenAccent[400]!.withAlpha(40),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.monetization_on_rounded,
          color: Colors.greenAccent[400]!,
          size: 24,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: categoryColor.withAlpha(40),
        shape: BoxShape.circle,
      ),
      child: Icon(
        category?.icon ?? Icons.shopping_bag_rounded,
        color: categoryColor,
        size: 24,
      ),
    );
  }

  Widget _buildExpenseInfo(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
    dynamic category,
  ) {
    final String dateText = showFullDate
        ? DateFormat('dd/MM/yyyy').format(expense.date)
        : DateUtils.getRelativeDate(expense.date);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AutoSizeText(
            expense.location?.isNotEmpty == true
                ? expense.location!
                : (expense.isIncome == true
                      ? 'Receita'
                      : (category?.name ?? 'Despesa Geral')),
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
            maxLines: 1,
            minFontSize: 14,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            dateText,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(
    TextTheme textTheme,
    NumberFormat currencyFormatter,
    ColorScheme colorScheme,
  ) {
    final isIncome = expense.isIncome == true;
    final amountText = currencyFormatter.format(expense.amount);
    final text = isIncome ? '+ $amountText' : '- $amountText';
    return Text(
      text,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: isIncome ? Colors.greenAccent[400] : colorScheme.error,
        fontSize: 15,
      ),
    );
  }
}
