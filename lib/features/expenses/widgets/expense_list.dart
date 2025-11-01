import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/widgets/activity_tile_widget.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';

class ExpenseList extends StatefulWidget {
  final List<Expense> monthlyExpenses;

  const ExpenseList({
    super.key,
    required this.monthlyExpenses,
  });

  @override
  State<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends State<ExpenseList> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseViewModel>(context, listen: false).listKey = _listKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.defaultPadding, 0, AppTheme.defaultPadding, 96.0),
      sliver: SliverAnimatedList(
        key: _listKey,
        initialItemCount: widget.monthlyExpenses.length,
        itemBuilder: (context, index, animation) {
          final expense = widget.monthlyExpenses[index];
          return _buildExpenseTile(expense, index, animation);
        },
      ),
    );
  }

  Widget _buildExpenseTile(
      Expense expense, int index, Animation<double> animation) {
    return AnimatedListItem(
      animation: animation,
      child: ActivityTile(
        key: ValueKey(expense),
        expense: expense,
        index: index,
      ),
    );
  }
}
