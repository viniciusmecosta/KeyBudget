import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/activity_tile_widget.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class ExpenseList extends ConsumerWidget {
  final List<Expense> monthlyExpenses;

  const ExpenseList({super.key, required this.monthlyExpenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAllPeriods = ref.watch(expenseViewModelProvider).searchAllPeriods;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, 96.0),
      sliver: SliverList.builder(
        itemCount: monthlyExpenses.length,
        itemBuilder: (context, index) {
          final expense = monthlyExpenses[index];
          return ActivityTile(
            key: ValueKey(expense.id ?? 'expense_$index'),
            expense: expense,
            index: index,
            showFullDate: isAllPeriods,
          );
        },
      ),
    );
  }
}
