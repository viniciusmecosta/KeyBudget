import 'package:flutter/material.dart';
import 'package:key_budget/core/import_export/csv_import_parser.dart';
import 'package:key_budget/core/import_export/import_preview_screen.dart';
import 'package:key_budget/core/import_export/import_service.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/data_import_service.dart';
import 'package:key_budget/core/services/pdf_service.dart';
import 'package:key_budget/core/services/snackbar_service.dart';

class CredentialTransferService {
  final CsvService csvService;
  final PdfService pdfService;
  final DataImportService dataImportService;
  final ImportService importService;

  const CredentialTransferService({
    required this.csvService,
    required this.pdfService,
    required this.dataImportService,
    required this.importService,
  });

  Future<bool> exportCsv(
    BuildContext context,
    List<Credential> credentials,
    String Function(String) decryptPassword,
  ) => csvService.exportCredentials(context, credentials, decryptPassword);

  Future<void> exportPdf(
    BuildContext context,
    List<Credential> credentials,
    String Function(String) decryptPassword,
  ) => pdfService.exportCredentialsPdf(context, credentials, decryptPassword);

  Future<int> importCsv(
    String userId,
    List<Credential> credentials,
    String? folderId, {
    BuildContext? context,
    String? rawCsvContent,
    String? fileName,
  }) async {
    try {
      String? content = rawCsvContent;
      String name = fileName ?? 'credentials.csv';
      if (content == null) {
        final file = await csvService.pickCsvFile();
        if (file == null) return 0;
        name = file.uri.pathSegments.last;
        content = await file.readAsString();
      }

      final plan = await importService.preparePlan(
        userId: userId,
        fileContent: content,
        fileName: name,
        forcedType: CsvImportType.credentials,
        existingCredentials: credentials,
        defaultFolderId: folderId,
      );

      if (!plan.canProceed) {
        if (context != null && context.mounted) {
          SnackbarService.showError(
            context,
            plan.globalErrors.isNotEmpty
                ? plan.globalErrors.first
                : 'O arquivo CSV não possui credenciais válidas para importar.',
          );
        }
        return 0;
      }

      if (context != null && context.mounted) {
        final resultCount = await Navigator.of(context).push<int>(
          MaterialPageRoute(
            builder: (_) => ImportPreviewScreen(
              userId: userId,
              plan: plan,
              importService: importService,
            ),
          ),
        );
        return resultCount ?? 0;
      }
      final result = await importService.applyPlan(
        userId: userId,
        plan: plan,
        importOnlyValid: true,
      );
      return result.data?.createdCount ?? 0;
    } catch (_) {
      if (context != null && context.mounted) {
        SnackbarService.showError(
          context,
          'Não foi possível importar as credenciais. Verifique o arquivo e tente novamente.',
        );
      }
      return 0;
    }
  }

  Future<int> importLegacyJson(String userId) =>
      dataImportService.importCredentialsFromJson(userId);
}
