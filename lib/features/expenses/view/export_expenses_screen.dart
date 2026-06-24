import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class ExportExpensesScreen extends ConsumerStatefulWidget {
  const ExportExpensesScreen({super.key});

  @override
  ConsumerState<ExportExpensesScreen> createState() =>
      _ExportExpensesScreenState();
}

class _ExportExpensesScreenState extends ConsumerState<ExportExpensesScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _export(BuildContext context,
      {required bool all, required String type}) async {
    final viewModel = ref.read(expenseViewModelProvider);
    final analysisViewModel = ref.read(analysisViewModelProvider);
    final categoryViewModel = ref.read(categoryViewModelProvider);
    final scaffoldContext = context;

    if (!all && (_startDate == null || _endDate == null)) {
      SnackbarService.showError(
          scaffoldContext, 'Por favor, selecione um período.');
      return;
    }

    bool success = false;
    try {
      if (type == 'csv') {
        success = await viewModel.exportExpensesToCsv(
          scaffoldContext,
          all ? null : _startDate!,
          all ? null : _endDate!,
        );
        if (!scaffoldContext.mounted) return;
        if (success) {
          SnackbarService.showSuccess(
              scaffoldContext, 'Arquivo CSV exportado com sucesso!');
        } else if (!viewModel.isExportingCsv) {
          SnackbarService.showError(
              scaffoldContext, 'Falha ao exportar arquivo.');
        }
      } else if (type == 'pdf') {
        await viewModel.exportExpensesToPdf(
          scaffoldContext,
          all ? null : _startDate!,
          all ? null : _endDate!,
          analysisViewModel,
          categoryViewModel,
        );
      }
    } catch (e) {
      if (!scaffoldContext.mounted) return;
      SnackbarService.showError(scaffoldContext, 'Erro durante a exportação.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(expenseViewModelProvider);
    final isExporting = viewModel.isExportingCsv || viewModel.isExportingPdf;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Despesas'),
      ),
      body: AppAnimations.fadeInFromBottom(Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton(
              onPressed: isExporting ? null : _pickDateRange,
              icon: Icons.date_range,
              label: 'Selecionar Período',
              variant: AppButtonVariant.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_startDate != null && _endDate != null)
              Text(
                'Período: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              onPressed: isExporting || _startDate == null || _endDate == null
                  ? null
                  : () => _export(context, all: false, type: 'csv'),
              isLoading: viewModel.isExportingCsv,
              label: 'Exportar Período (CSV)',
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              onPressed: isExporting || _startDate == null || _endDate == null
                  ? null
                  : () => _export(context, all: false, type: 'pdf'),
              isLoading: viewModel.isExportingPdf,
              label: 'Exportar Período (PDF)',
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              onPressed: isExporting
                  ? null
                  : () => _export(context, all: true, type: 'csv'),
              isLoading: viewModel.isExportingCsv,
              label: 'Exportar Histórico (CSV)',
              variant: AppButtonVariant.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              onPressed: isExporting
                  ? null
                  : () => _export(context, all: true, type: 'pdf'),
              isLoading: viewModel.isExportingPdf,
              label: 'Exportar Histórico (PDF)',
              variant: AppButtonVariant.outline,
            ),
          ],
        ),
      )),
    );
  }
}
