import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart' hide DateUtils;
import 'package:intl/intl.dart';
import 'package:key_budget/app/config/app_theme.dart';
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

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: colorScheme.outline.withAlpha((255 * 0.08).round()),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha((255 * 0.04).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: InkWell(
          onTap: () => _navigateToDetail(context),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            child: Row(
              children: [
                _buildCategoryIcon(categoryColor, category),
                const SizedBox(width: AppTheme.spaceM),
                _buildExpenseInfo(context, textTheme, colorScheme, category),
                const SizedBox(width: AppTheme.spaceS),
                _buildAmountInfo(textTheme, currencyFormatter),
              ],
            ),
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
        borderRadius: BorderRadius.circular(AppTheme.spaceS + 2),
        border: Border.all(
          color: categoryColor.withAlpha((255 * 0.2).round()),
          width: 1,
        ),
      ),
      child: Icon(
        category?.icon ?? Icons.shopping_bag_rounded,
        color: categoryColor,
        size: 20,
      ),
    );
  }

  Widget _buildExpenseInfo(BuildContext context, TextTheme textTheme,
      ColorScheme colorScheme, category) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color:
                    colorScheme.onSurfaceVariant.withAlpha((255 * 0.7).round()),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  DateUtils.getRelativeDate(expense.date),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant
                        .withAlpha((255 * 0.8).round()),
                    fontSize: 12,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(TextTheme textTheme, NumberFormat currencyFormatter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          currencyFormatter.format(expense.amount),
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.error,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ExpenseDetailScreen(expense: expense),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
