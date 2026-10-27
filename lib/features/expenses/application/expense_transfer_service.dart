import 'package:passfin/app/utils/navigation_utils.dart';
import 'package:flutter/material.dart';
import 'package:passfin/core/import_export/csv_import_parser.dart';
import 'package:passfin/core/import_export/import_preview_screen.dart';
import 'package:passfin/core/import_export/import_service.dart';
import 'package:passfin/core/models/expense_model.dart';
import 'package:passfin/core/services/csv_service.dart';
import 'package:passfin/core/services/data_import_service.dart';
import 'package:passfin/core/services/pdf_service.dart';
import 'package:passfin/core/services/snackbar_service.dart';
import 'package:passfin/core/time/date_range.dart';
import 'package:passfin/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:passfin/features/category/viewmodel/category_viewmodel.dart';
import 'package:passfin/features/expenses/repository/expense_repository.dart';

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
    if (userId == null) {
      return selectExpenses(currentExpenses, start, end);
    }
    if ((start == null) != (end == null)) return null;
    final range = start == null ? null : DateRange.fromDays(start, end!);
    final selected = await expenseRepository.getAllPaged(
      userId,
      startInclusive: range?.startInclusive,
      endExclusive: range?.endExclusive,
      requireServer: true,
    );
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
      final count = await NavigationUtils.push<int>(
        context,
        ImportPreviewScreen(
          userId: userId,
          plan: plan,
          importService: importService,
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
