import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class ExportExpensesScreen extends StatefulWidget {
  const ExportExpensesScreen({super.key});

  @override
  State<ExportExpensesScreen> createState() => _ExportExpensesScreenState();
}

class _ExportExpensesScreenState extends State<ExportExpensesScreen> {
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
    final viewModel = Provider.of<ExpenseViewModel>(context, listen: false);
    final analysisViewModel =
        Provider.of<AnalysisViewModel>(context, listen: false);
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);
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
    final viewModel = context.watch<ExpenseViewModel>();
    final isExporting = viewModel.isExportingCsv || viewModel.isExportingPdf;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Despesas'),
      ),
      body: AppAnimations.fadeInFromBottom(Padding(
        padding: const EdgeInsets.all(AppTheme.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: const Text('Selecionar Período'),
              onPressed: isExporting ? null : _pickDateRange,
            ),
            const SizedBox(height: 16),
            if (_startDate != null && _endDate != null)
              Text(
                'Período: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isExporting || _startDate == null || _endDate == null
                  ? null
                  : () => _export(context, all: false, type: 'csv'),
              child: viewModel.isExportingCsv
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: theme.colorScheme.onPrimary, strokeWidth: 2.0))
                  : const Text('Exportar Período Selecionado (CSV)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isExporting || _startDate == null || _endDate == null
                  ? null
                  : () => _export(context, all: false, type: 'pdf'),
              child: viewModel.isExportingPdf
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: theme.colorScheme.onPrimary, strokeWidth: 2.0))
                  : const Text('Exportar Período Selecionado (PDF)'),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: isExporting
                  ? null
                  : () => _export(context, all: true, type: 'csv'),
              child: viewModel.isExportingCsv
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.0))
                  : const Text('Exportar Todo o Histórico (CSV)'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: isExporting
                  ? null
                  : () => _export(context, all: true, type: 'pdf'),
              child: viewModel.isExportingPdf
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.0))
                  : const Text('Exportar Todo o Histórico (PDF)'),
            ),
          ],
        ),
      )),
    );
  }
}
