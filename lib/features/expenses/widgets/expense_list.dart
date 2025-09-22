import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/app/config/app_theme.dart';
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
      return tile
          .animate(delay: Duration(milliseconds: 50 * index))
          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
          .slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
    }

    return tile;
  }
}
