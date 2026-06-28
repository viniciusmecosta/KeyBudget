import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/activity_tile_widget.dart';
import 'package:key_budget/app/widgets/animated_list_item.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class ExpenseList extends ConsumerStatefulWidget {
  final List<Expense> monthlyExpenses;

  const ExpenseList({
    super.key,
    required this.monthlyExpenses,
  });

  @override
  ConsumerState<ExpenseList> createState() => _ExpenseListState();
}

class _ExpenseListState extends ConsumerState<ExpenseList> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseViewModelProvider).setListKey(_listKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96.0),
      sliver: SliverAnimatedList(
        key: _listKey,
        initialItemCount: widget.monthlyExpenses.length,
        itemBuilder: (context, index, animation) {
          if (index >= widget.monthlyExpenses.length) {
            return const SizedBox.shrink();
          }
          final expense = widget.monthlyExpenses[index];
          return _buildExpenseTile(expense, index, animation);
        },
      ),
    );
  }

  Widget _buildExpenseTile(
      Expense expense, int index, Animation<double> animation) {
    final isAllPeriods = ref.read(expenseViewModelProvider).searchAllPeriods;

    return AnimatedListItem(
      animation: animation,
      child: ActivityTile(
        key: ValueKey(expense.id),
        expense: expense,
        index: index,
        showFullDate: isAllPeriods,
      ),
    );
  }
}
