import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/repository/recurring_expense_repository.dart';
import 'csv_import_parser.dart';
import 'import_validation.dart';

class ImportExecutionPlan {
  final String fileHash;
  final String fileName;
  final CsvImportType detectedType;
  final int totalLines;
  final List<ImportLineValidation<dynamic>> lineResults;
  final int totalIncomeMinor;
  final int totalExpenseMinor;
  final List<String> globalErrors;
  final List<String> globalWarnings;

  const ImportExecutionPlan({
    required this.fileHash,
    required this.fileName,
    required this.detectedType,
    required this.totalLines,
    required this.lineResults,
    required this.totalIncomeMinor,
    required this.totalExpenseMinor,
    this.globalErrors = const [],
    this.globalWarnings = const [],
  });

  int get validCount => lineResults.where((l) => l.isValid && l.status != ImportRowStatus.skippedDuplicate).length;
  int get invalidCount => lineResults.where((l) => l.hasErrors).length;
  int get warningCount => lineResults.where((l) => l.hasWarnings && !l.hasErrors).length;
  int get skippedCount => lineResults.where((l) => l.status == ImportRowStatus.skippedDuplicate).length;
  int get conflictCount => lineResults.where((l) => l.status == ImportRowStatus.conflict).length;

  bool get hasErrors => globalErrors.isNotEmpty || invalidCount > 0;
  bool get canProceed => validCount > 0 && globalErrors.isEmpty;
}

class ImportReport {
  final String operationId;
  final int createdCount;
  final int skippedCount;
  final int failedCount;
  final List<String> createdIds;
  final List<String> errors;

  const ImportReport({
    required this.operationId,
    required this.createdCount,
    required this.skippedCount,
    required this.failedCount,
    required this.createdIds,
    this.errors = const [],
  });
}

class ImportService {
  final ExpenseRepository expenseRepository;
  final CredentialRepository credentialRepository;
  final RecurringExpenseRepository recurringRepository;
  final EncryptionService? _customEncryptionService;
  final CsvImportParser csvParser;

  ImportService({
    required this.expenseRepository,
    required this.credentialRepository,
    required this.recurringRepository,
    EncryptionService? encryptionService,
    this.csvParser = const CsvImportParser(),
  }) : _customEncryptionService = encryptionService;

  EncryptionService get encryptionService =>
      _customEncryptionService ?? EncryptionService();

  Future<ImportExecutionPlan> preparePlan({
    required String userId,
    required String fileContent,
    required String fileName,
    CsvImportType? forcedType,
    List<ExpenseCategory> availableCategories = const [],
    List<Expense> existingExpenses = const [],
    List<Credential> existingCredentials = const [],
    String? defaultFolderId,
    String? explicitDelimiter,
  }) async {
    final fileHash = sha256.convert(utf8.encode(fileContent)).toString();
    final parseResult = csvParser.parseString(
      fileContent,
      explicitDelimiter: explicitDelimiter,
    );

    if (!parseResult.isValid) {
      return ImportExecutionPlan(
        fileHash: fileHash,
        fileName: fileName,
        detectedType: parseResult.detectedType,
        totalLines: parseResult.totalRows,
        lineResults: [],
        totalIncomeMinor: 0,
        totalExpenseMinor: 0,
        globalErrors: parseResult.structuralErrors,
      );
    }

    final effectiveType = forcedType ?? parseResult.detectedType;
    if (effectiveType == CsvImportType.unknown) {
      return ImportExecutionPlan(
        fileHash: fileHash,
        fileName: fileName,
        detectedType: CsvImportType.unknown,
        totalLines: parseResult.totalRows,
        lineResults: [],
        totalIncomeMinor: 0,
        totalExpenseMinor: 0,
        globalErrors: [
          'Não foi possível identificar o tipo de arquivo. Verifique se o cabeçalho contém colunas esperadas para despesas, credenciais ou categorias.',
        ],
      );
    }

    final fileHashPrefix = fileHash.substring(0, 8);

    final Map<String, int> contentOccurrenceCounter = {};
    final List<ImportLineValidation<dynamic>> lineResults = [];

    int totalIncomeMinor = 0;
    int totalExpenseMinor = 0;

    for (final rawRow in parseResult.rows) {
      final rawSignature = rawRow.values.entries.map((e) => '${e.key}:${e.value}').join(';');
      final occurrenceIndex = (contentOccurrenceCounter[rawSignature] ?? 0) + 1;
      contentOccurrenceCounter[rawSignature] = occurrenceIndex;

      switch (effectiveType) {
        case CsvImportType.expenses:
          final validation = ImportValidation.validateExpenseRow(
            rawRow: rawRow,
            occurrenceIndex: occurrenceIndex,
            availableCategories: availableCategories,
          );

          if (validation.isValid && validation.parsedItem != null) {
            final exp = validation.parsedItem!;

            if (exp.isIncome ?? false) {
              totalIncomeMinor += exp.money.amountMinor;
            } else {
              totalExpenseMinor += exp.money.amountMinor;
            }

            final targetDocId = exp.id ?? 'imp_${fileHashPrefix}_${rawRow.lineNumber}_${validation.deduplicationFingerprint.substring(0, 8)}';
            final existing = existingExpenses.where((e) => e.id == targetDocId || (exp.id != null && e.id == exp.id)).toList();
            if (existing.isNotEmpty) {
              final isIdentical = existing.first.amountMinor == exp.money.amountMinor &&
                  existing.first.date == exp.date &&
                  existing.first.categoryId == exp.categoryId;
              if (isIdentical) {
                lineResults.add(
                  ImportLineValidation<Expense>(
                    lineNumber: validation.lineNumber,
                    rawValues: validation.rawValues,
                    parsedItem: exp.copyWith(id: targetDocId),
                    errors: const [],
                    warnings: ['Registro idêntico já presente no banco de dados.'],
                    originalId: exp.id,
                    deduplicationFingerprint: validation.deduplicationFingerprint,
                    status: ImportRowStatus.skippedDuplicate,
                  ),
                );
                continue;
              } else {
                lineResults.add(
                  ImportLineValidation<Expense>(
                    lineNumber: validation.lineNumber,
                    rawValues: validation.rawValues,
                    parsedItem: exp.copyWith(id: targetDocId),
                    errors: const [],
                    warnings: ['ID existente no banco porém com valores diferentes.'],
                    originalId: exp.id,
                    deduplicationFingerprint: validation.deduplicationFingerprint,
                    status: ImportRowStatus.conflict,
                  ),
                );
                continue;
              }
            }
          }
          lineResults.add(validation);
          break;

        case CsvImportType.credentials:
          final validation = ImportValidation.validateCredentialRow(
            rawRow: rawRow,
            occurrenceIndex: occurrenceIndex,
            defaultFolderId: defaultFolderId,
          );

          if (validation.isValid && validation.parsedItem != null) {
            final cred = validation.parsedItem!;
            final targetDocId = cred.id ?? 'cred_imp_${fileHashPrefix}_${rawRow.lineNumber}';
            final existing = existingCredentials.where((c) => c.id == targetDocId || (cred.id != null && c.id == cred.id)).toList();
            if (existing.isNotEmpty) {
              lineResults.add(
                ImportLineValidation<Credential>(
                  lineNumber: validation.lineNumber,
                  rawValues: validation.rawValues,
                  parsedItem: cred.copyWith(id: targetDocId),
                  errors: const [],
                  warnings: ['Credencial já existe no banco.'],
                  originalId: cred.id,
                  deduplicationFingerprint: validation.deduplicationFingerprint,
                  status: ImportRowStatus.skippedDuplicate,
                ),
              );
              continue;
            }
          }
          lineResults.add(validation);
          break;

        case CsvImportType.recurringExpenses:
          final validation = ImportValidation.validateRecurringRow(
            rawRow: rawRow,
            occurrenceIndex: occurrenceIndex,
          );
          lineResults.add(validation);
          break;

        default:
          break;
      }
    }

    return ImportExecutionPlan(
      fileHash: fileHash,
      fileName: fileName,
      detectedType: effectiveType,
      totalLines: parseResult.totalRows,
      lineResults: lineResults,
      totalIncomeMinor: totalIncomeMinor,
      totalExpenseMinor: totalExpenseMinor,
    );
  }

  Future<OperationResult<ImportReport>> applyPlan({
    required String userId,
    required ImportExecutionPlan plan,
    bool importOnlyValid = true,
  }) async {
    try {
      final eligibleLines = plan.lineResults.where((l) {
        if (!l.isValid) return false;
        if (l.status == ImportRowStatus.skippedDuplicate) return false;
        return true;
      }).toList();

      if (eligibleLines.isEmpty) {
        return OperationResult.failed(
          safeError: 'Nenhum registro elegível para importação.',
        );
      }

      final fileHashPrefix = plan.fileHash.substring(0, 8);
      final operationId = 'import_${fileHashPrefix}_${DateTime.now().millisecondsSinceEpoch}';
      final List<String> createdIds = [];

      switch (plan.detectedType) {
        case CsvImportType.expenses:
          final List<Expense> toAdd = [];
          for (final line in eligibleLines) {
            final exp = line.parsedItem as Expense;

            final docId = exp.id ?? 'imp_${fileHashPrefix}_${line.lineNumber}_${line.deduplicationFingerprint.substring(0, 8)}';
            toAdd.add(exp.copyWith(id: docId));
            createdIds.add(docId);
          }
          await expenseRepository.addExpensesBatch(userId, toAdd);
          break;

        case CsvImportType.credentials:
          for (final line in eligibleLines) {
            final cred = line.parsedItem as Credential;
            final docId = cred.id ?? 'cred_imp_${fileHashPrefix}_${line.lineNumber}';

            final encryptedPassword = encryptionService.encryptData(cred.encryptedPassword);
            final readyCred = cred.copyWith(
              id: docId,
              encryptedPassword: encryptedPassword,
            );
            await credentialRepository.addCredential(userId, readyCred);
            createdIds.add(docId);
          }
          break;

        case CsvImportType.recurringExpenses:
          for (final line in eligibleLines) {
            final rule = line.parsedItem as RecurringExpense;
            final docId = rule.id ?? 'rec_imp_${fileHashPrefix}_${line.lineNumber}';
            await recurringRepository.addRecurringExpense(
              userId,
              rule.copyWith(id: docId),
            );
            createdIds.add(docId);
          }
          break;

        default:
          return OperationResult.failed(
            safeError: 'Tipo de importação não suportado.',
          );
      }

      return OperationResult.completed(
        data: ImportReport(
          operationId: operationId,
          createdCount: createdIds.length,
          skippedCount: plan.skippedCount,
          failedCount: plan.invalidCount,
          createdIds: createdIds,
        ),
        count: createdIds.length,
        affectedIds: createdIds,
      );
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Não foi possível concluir a importação. Verifique os dados e tente novamente.',
      );
    }
  }

  Future<OperationResult<void>> rollbackImport({
    required String userId,
    required ImportReport report,
    required CsvImportType type,
  }) async {
    try {
      for (final id in report.createdIds) {
        if (type == CsvImportType.expenses) {
          await expenseRepository.deleteExpense(userId, id);
        } else if (type == CsvImportType.credentials) {
          await credentialRepository.deleteCredential(userId, id);
        } else if (type == CsvImportType.recurringExpenses) {
          await recurringRepository.deleteRecurringExpense(userId, id);
        }
      }
      return OperationResult.completed(count: report.createdIds.length);
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Não foi possível desfazer a importação. Tente novamente.',
      );
    }
  }
}

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    expenseRepository: ref.read(expenseRepositoryProvider),
    credentialRepository: ref.read(credentialRepositoryProvider),
    recurringRepository: ref.read(recurringExpenseRepositoryProvider),
  );
});
