import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/expenses/view/export_expenses_screen.dart';
import 'package:key_budget/features/expenses/view/recurring_expenses_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class ExpenseActionsPopupMenu extends StatelessWidget {
  const ExpenseActionsPopupMenu({super.key});

  void _import(BuildContext context) async {
    final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final scaffoldContext = context;

    final count =
        await viewModel.importExpensesFromCsv(authViewModel.currentUser!.id);
    if (!scaffoldContext.mounted) return;
    SnackbarService.showSuccess(
        scaffoldContext, '$count despesas importadas com sucesso!');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<ExpenseViewModel>();

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: theme.colorScheme.onSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'recurring',
          child: Row(
            children: [
              Icon(Icons.replay_circle_filled_rounded),
              SizedBox(width: AppTheme.spaceS),
              Text('Despesas Recorrentes'),
            ],
          ),
        ),
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
              const SizedBox(width: AppTheme.spaceS),
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
              const SizedBox(width: AppTheme.spaceS),
              const Text('Exportar Despesas'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'import') _import(context);
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
