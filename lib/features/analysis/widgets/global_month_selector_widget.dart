import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';

import '../viewmodel/analysis_viewmodel.dart';
import 'category_analysis_section_widget.dart'; // For StringCapitalize extension

class GlobalMonthSelectorWidget extends ConsumerWidget {
  const GlobalMonthSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(analysisViewModelProvider);
    final theme = Theme.of(context);

    if (viewModel.availableMonthsForFilter.isEmpty ||
        viewModel.selectedMonthForCategory == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showMonthPicker(context, viewModel),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtro Global (Período)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMM('pt_BR')
                          .format(viewModel.selectedMonthForCategory!)
                          .capitalize(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context, AnalysisViewModel viewModel) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bc) => SizedBox(
        height: 400,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(
                  (255 * 0.3).round(),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Selecionar Período',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: viewModel.availableMonthsForFilter.length,
                itemBuilder: (context, index) {
                  final month = viewModel.availableMonthsForFilter[index];
                  final isSelected =
                      month == viewModel.selectedMonthForCategory;

                  final monthExpenses = viewModel.allExpenses.where(
                    (exp) =>
                        exp.isIncome != true &&
                        exp.date.year == month.year &&
                        exp.date.month == month.month,
                  );

                  final monthTotal = monthExpenses.fold(
                    0.0,
                    (sum, exp) => sum + exp.amount,
                  );

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 4,
                    ),
                    child: Material(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () {
                          viewModel.setSelectedMonthForCategory(month);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat.yMMMM(
                                        'pt_BR',
                                      ).format(month).capitalize(),
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? theme
                                                  .colorScheme
                                                  .onPrimaryContainer
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (monthTotal > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'pt_BR',
                                          symbol: 'R\$',
                                        ).format(monthTotal),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
