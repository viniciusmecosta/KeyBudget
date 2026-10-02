import 'package:flutter/material.dart';
import 'package:key_budget/core/import_export/csv_import_parser.dart';
import 'package:key_budget/core/import_export/import_preview_screen.dart';
import 'package:key_budget/core/import_export/import_service.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/data_import_service.dart';
import 'package:key_budget/core/services/pdf_service.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/core/time/date_range.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';

class ExpenseTransferService {
  final ImportService importService;
  final CsvService csvService;
  final PdfService pdfService;
  final DataImportService dataImportService;
  final ExpenseRepository expenseRepository;

  const ExpenseTransferService({
    required this.importService,
    required this.csvService,
    required this.pdfService,
    required this.dataImportService,
    required this.expenseRepository,
  });

  List<Expense>? selectExpenses(
    List<Expense> source,
    DateTime? start,
    DateTime? end,
  ) {
    if ((start == null) != (end == null)) return null;
    final range = start == null ? null : DateRange.fromDays(start, end!);
    return [
      for (final expense in source)
        if (range == null || range.contains(expense.date)) expense,
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<Expense>?> _loadForExport(
    String? userId,
    List<Expense> currentExpenses,
    DateTime? start,
    DateTime? end,
  ) async {
    if (start == null || end == null || userId == null) {
      return selectExpenses(currentExpenses, start, end);
    }
    final range = DateRange.fromDays(start, end);
    final selected = <Expense>[];
    var page = await expenseRepository.getHistoryPage(
      userId,
      startInclusive: range.startInclusive,
      endExclusive: range.endExclusive,
    );
    selected.addAll(page.expenses);
    while (page.nextCursor != null) {
      page = await expenseRepository.getHistoryPage(
        userId,
        startInclusive: range.startInclusive,
        endExclusive: range.endExclusive,
        after: page.nextCursor,
      );
      selected.addAll(page.expenses);
    }
    return selected..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<bool> exportCsv(
    BuildContext context,
    String? userId,
    List<Expense> expenses,
    DateTime? start,
    DateTime? end,
  ) async {
    final selected = await _loadForExport(userId, expenses, start, end);
    if (!context.mounted) return false;
    return selected == null
        ? false
        : csvService.exportExpenses(context, selected);
  }

  Future<void> exportPdf(
    BuildContext context,
    String? userId,
    List<Expense> expenses,
    DateTime? start,
    DateTime? end,
    AnalysisViewModel analysisViewModel,
    CategoryViewModel categoryViewModel,
  ) async {
    final selected = await _loadForExport(userId, expenses, start, end);
    if (selected == null || !context.mounted) return;
    await pdfService.exportExpensesPdf(
      context,
      selected,
      analysisViewModel,
      categoryViewModel,
    );
  }

  Future<int> importCsv(
    String userId,
    List<Expense> existingExpenses, {
    BuildContext? context,
    String? rawCsvContent,
    String? fileName,
  }) async {
    String? content = rawCsvContent;
    String name = fileName ?? 'expenses.csv';
    if (content == null) {
      final file = await csvService.pickCsvFile();
      if (file == null) return 0;
      name = file.path.split('/').last;
      content = await file.readAsString();
    }

    final plan = await importService.preparePlan(
      userId: userId,
      fileContent: content,
      fileName: name,
      forcedType: CsvImportType.expenses,
      existingExpenses: existingExpenses,
    );
    if (!plan.canProceed) {
      if (context != null && context.mounted) {
        SnackbarService.showError(
          context,
          plan.globalErrors.isNotEmpty
              ? plan.globalErrors.first
              : 'O arquivo CSV não possui registros válidos para importar.',
        );
      }
      return 0;
    }

    if (context != null && context.mounted) {
      final count = await Navigator.of(context).push<int>(
        MaterialPageRoute(
          builder: (_) => ImportPreviewScreen(
            userId: userId,
            plan: plan,
            importService: importService,
          ),
        ),
      );
      return count ?? 0;
    }
    final result = await importService.applyPlan(
      userId: userId,
      plan: plan,
      importOnlyValid: true,
    );
    return result.data?.createdCount ?? 0;
  }

  Future<int> importLegacyJson(String userId) =>
      dataImportService.importExpensesFromJsons(userId);
}
