import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/utils/date_utils.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/view/expense_detail_screen.dart';
import 'package:provider/provider.dart';

class ActivityTile extends StatelessWidget {
  final Expense expense;
  final int index;

  const ActivityTile({
    super.key,
    required this.expense,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final category = Provider.of<CategoryViewModel>(context, listen: false)
        .getCategoryById(expense.categoryId);

    final categoryColor = category?.color ?? colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () =>
            NavigationUtils.push(context, ExpenseDetailScreen(expense: expense)),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Row(
            children: [
              _buildCategoryIcon(categoryColor, category),
              const SizedBox(width: AppTheme.spaceM),
              _buildExpenseInfo(context, textTheme, colorScheme, category),
              const SizedBox(width: AppTheme.spaceS),
              _buildAmountInfo(textTheme, currencyFormatter, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(Color categoryColor, category) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceS + 2),
      decoration: BoxDecoration(
        color: categoryColor.withAlpha((255 * 0.12).round()),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Icon(
        category?.icon ?? Icons.shopping_bag_rounded,
        color: categoryColor,
        size: 22,
      ),
    );
  }

  Widget _buildExpenseInfo(BuildContext context, TextTheme textTheme,
      ColorScheme colorScheme, category) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AutoSizeText(
            expense.location?.isNotEmpty == true
                ? expense.location!
                : (category?.name ?? 'Gasto Geral'),
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
            DateUtils.getRelativeDate(expense.date),
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
      TextTheme textTheme, NumberFormat currencyFormatter, colorScheme) {
    return Text(
      currencyFormatter.format(expense.amount),
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.negativeChange,
        fontSize: 15,
      ),
    );
  }
}
