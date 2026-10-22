import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';

/// Uses the dashboard's existing data, without another database subscription.
class DashboardCategorySummary extends ConsumerWidget {
  const DashboardCategorySummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(dashboardViewModelProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final totals = <String?, int>{};
    for (final expense in model.allExpenses) {
      if (expense.isIncome == true ||
          expense.date.year != now.year ||
          expense.date.month != now.month ||
          !expense.date.isBefore(tomorrow)) {
        continue;
      }
      totals.update(
        expense.categoryId,
        (value) => value + expense.money.amountMinor,
        ifAbsent: () => expense.money.amountMinor,
      );
    }
    final ordered = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = totals.values.fold<int>(0, (sum, value) => sum + value);
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gastos por categoria', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Realizados neste mês • participação no total',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (ordered.isEmpty)
            const Text(
              'Suas categorias aparecerão aqui quando você registrar uma despesa.',
            ),
          for (final entry in ordered) ...[
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  model.categoryViewModel.getCategoryById(entry.key)?.name ??
                      'Sem categoria',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  currency.format(entry.value / 100),
                  style: theme.textTheme.labelLarge,
                ),
                Text(
                  '${total > 0 ? (entry.value * 100 / total).toStringAsFixed(1).replaceAll('.', ',') : '0'}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: total > 0 ? (entry.value / total).clamp(0, 1) : 0,
              minHeight: 5,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
