import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/app/widgets/activity_tile_widget.dart';
import 'package:key_budget/core/models/expense_model.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> monthlyExpenses;
  final bool isFirstLoad;

  const ExpenseList({
    super.key,
    required this.monthlyExpenses,
    required this.isFirstLoad,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.defaultPadding, 0, AppTheme.defaultPadding, 96.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final expense = monthlyExpenses[index];
            return _buildExpenseTile(expense, index);
          },
          childCount: monthlyExpenses.length,
        ),
      ),
    );
  }

  Widget _buildExpenseTile(Expense expense, int index) {
    Widget tile = ActivityTile(
      expense: expense,
      index: index,
    );

    if (isFirstLoad) {
      return AppAnimations.listFadeIn(tile, index: index);
    }

    return tile;
  }
}
