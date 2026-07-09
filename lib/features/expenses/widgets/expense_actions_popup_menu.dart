import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/expenses/view/export_expenses_screen.dart';
import 'package:key_budget/features/expenses/view/recurring_expenses_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class ExpenseActionsPopupMenu extends ConsumerWidget {
  const ExpenseActionsPopupMenu({super.key});

  void _import(BuildContext context, WidgetRef ref) async {
    final viewModel = ref.read(expenseViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider);
    final scaffoldContext = context;

    final count =
        await viewModel.importExpensesFromCsv(authViewModel.currentUser!.id);

    if (scaffoldContext.mounted) {
      if (count > 0) {
        SnackbarService.showSuccess(
            scaffoldContext, '$count despesas importadas com sucesso!');
      } else {
        SnackbarService.showError(scaffoldContext, 'Nenhuma despesa importada');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final viewModel = ref.watch(expenseViewModelProvider);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: theme.colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.borderRadiusMD,
      ),
      itemBuilder: (context) {
        final authViewModel = ref.read(authViewModelProvider);
        final enableIncomes = authViewModel.currentUser?.enableIncomes ?? false;
        
        return [
          const PopupMenuItem(
            value: 'recurring',
            child: Row(
              children: [
                Icon(Icons.replay_circle_filled_rounded),
                SizedBox(width: AppSpacing.sm),
                Text('Despesas Recorrentes'),
              ],
            ),
          ),
          if (!enableIncomes) ...[
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'import',
              enabled: !viewModel.isExportingCsv && !viewModel.isExportingPdf,
              child: Row(
                children: [
                  Icon(
                    Icons.upload_file_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Importar de CSV'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export',
              enabled: !viewModel.isExportingCsv && !viewModel.isExportingPdf,
              child: Row(
                children: [
                  Icon(
                    Icons.download_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Exportar Despesas'),
                ],
              ),
            ),
          ],
        ];
      },
      onSelected: (value) {
        if (value == 'import') _import(context, ref);
        if (value == 'export') {
          NavigationUtils.push(context, const ExportExpensesScreen());
        }
        if (value == 'recurring') {
          NavigationUtils.push(context, const RecurringExpensesScreen());
        }
      },
    );
  }
}
