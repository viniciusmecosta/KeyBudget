import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/money/money_parser.dart';
import 'csv_import_parser.dart';

enum ImportRowStatus {
  valid,
  warning,
  invalid,
  conflict,
  skippedDuplicate,
}

class ImportLineValidation<T> {
  final int lineNumber;
  final Map<String, String> rawValues;
  final T? parsedItem;
  final List<String> errors;
  final List<String> warnings;
  final String? originalId;
  final String deduplicationFingerprint;
  final ImportRowStatus status;

  const ImportLineValidation({
    required this.lineNumber,
    required this.rawValues,
    this.parsedItem,
    this.errors = const [],
    this.warnings = const [],
    this.originalId,
    required this.deduplicationFingerprint,
    required this.status,
  });

  bool get isValid => errors.isEmpty && parsedItem != null;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}

class ImportValidation {

  static DateTime? parseStrictDate(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final ptBrRegex = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:[\sT](\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?');
    final ptMatch = ptBrRegex.firstMatch(clean);
    if (ptMatch != null) {
      final day = int.parse(ptMatch.group(1)!);
      final month = int.parse(ptMatch.group(2)!);
      final year = int.parse(ptMatch.group(3)!);
      final hour = ptMatch.group(4) != null ? int.parse(ptMatch.group(4)!) : 0;
      final minute = ptMatch.group(5) != null ? int.parse(ptMatch.group(5)!) : 0;
      final second = ptMatch.group(6) != null ? int.parse(ptMatch.group(6)!) : 0;

      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) return null;

      final parsed = DateTime(year, month, day, hour, minute, second);

      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        return null;
      }
      return parsed;
    }

    final isoRegex = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T\s](\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?');
    final isoMatch = isoRegex.firstMatch(clean);
    if (isoMatch != null) {
      final year = int.parse(isoMatch.group(1)!);
      final month = int.parse(isoMatch.group(2)!);
      final day = int.parse(isoMatch.group(3)!);
      final hour = isoMatch.group(4) != null ? int.parse(isoMatch.group(4)!) : 0;
      final minute = isoMatch.group(5) != null ? int.parse(isoMatch.group(5)!) : 0;
      final second = isoMatch.group(6) != null ? int.parse(isoMatch.group(6)!) : 0;

      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59) return null;

      final parsed = DateTime(year, month, day, hour, minute, second);
      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        return null;
      }
      return parsed;
    }

    return null;
  }

  static String generateRowFingerprint({
    required String type,
    required Map<String, String> normalizedFields,
    required int occurrenceIndex,
  }) {
    final sortedKeys = normalizedFields.keys.toList()..sort();
    final buffer = StringBuffer('$type|occ:$occurrenceIndex|');
    for (final k in sortedKeys) {

      if (k == 'password') continue;
      buffer.write('$k:${normalizedFields[k]};');
    }
    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }

  static ImportLineValidation<Expense> validateExpenseRow({
    required RawCsvRow rawRow,
    required int occurrenceIndex,
    required List<ExpenseCategory> availableCategories,
  }) {
    final values = rawRow.values;
    final List<String> errors = [];
    final List<String> warnings = [];

    if (rawRow.hasError) {
      errors.add(rawRow.parseError!);
      return ImportLineValidation<Expense>(
        lineNumber: rawRow.lineNumber,
        rawValues: values,
        errors: errors,
        deduplicationFingerprint: generateRowFingerprint(
          type: 'expense',
          normalizedFields: values,
          occurrenceIndex: occurrenceIndex,
        ),
        status: ImportRowStatus.invalid,
      );
    }

    final rawAmount = values['amount'];
    Money? parsedMoney;
    if (rawAmount == null || rawAmount.trim().isEmpty) {
      errors.add('Valor monetário não pode ser vazio.');
    } else {
      try {
        parsedMoney = MoneyParser.parse(rawAmount);
        if (parsedMoney.amountMinor < 0) {
          warnings.add('Valor informado é negativo (${parsedMoney.formatBrl()}).');
        }
      } on ExtraDecimalsException catch (e) {
        errors.add(e.toString());
      } catch (e) {
        errors.add('Valor monetário inválido "$rawAmount".');
      }
    }

    final rawDate = values['date'];
    DateTime? parsedDate;
    if (rawDate == null || rawDate.trim().isEmpty) {
      errors.add('Data é obrigatória e não pode ser vazia.');
    } else {
      parsedDate = parseStrictDate(rawDate);
      if (parsedDate == null) {
        errors.add('Data inválida "$rawDate". Datas inexistentes como 31/02 não são aceitas.');
      }
    }

    final rawCategoryId = values['categoryid'];
    String? resolvedCategoryId;
    if (rawCategoryId != null && rawCategoryId.trim().isNotEmpty) {
      final trimmedCat = rawCategoryId.trim();
      final directMatch = availableCategories.any((c) => c.id == trimmedCat);
      if (directMatch) {
        resolvedCategoryId = trimmedCat;
      } else {

        final nameMatches = availableCategories
            .where((c) => c.name.trim().toLowerCase() == trimmedCat.toLowerCase())
            .toList();
        if (nameMatches.length == 1) {
          resolvedCategoryId = nameMatches.first.id;
          warnings.add(
            'Categoria mapeada pelo nome "${nameMatches.first.name}" (ID $resolvedCategoryId).',
          );
        } else if (nameMatches.length > 1) {
          warnings.add(
            'Existem múltiplas categorias com o nome "$trimmedCat". Deixado sem categoria.',
          );
        } else {
          warnings.add(
            'Categoria "$trimmedCat" não foi encontrada no cadastro. Registro será importado sem categoria.',
          );
        }
      }
    }

    bool isIncome = false;
    final rawIsIncome = values['isincome']?.toLowerCase();
    if (rawIsIncome != null && rawIsIncome.isNotEmpty) {
      if (rawIsIncome == 'true' ||
          rawIsIncome == '1' ||
          rawIsIncome == 'sim' ||
          rawIsIncome == 'yes' ||
          rawIsIncome == 'receita' ||
          rawIsIncome == 'income') {
        isIncome = true;
      }
    }

    final recurringExpenseId = values['recurringexpenseid'] ?? values['recurring_expense_id'];
    final installmentGroupId = values['installmentgroupid'] ?? values['installment_group_id'];

    final originalId = values['id'];
    final fingerprint = generateRowFingerprint(
      type: 'expense',
      normalizedFields: values,
      occurrenceIndex: occurrenceIndex,
    );

    if (errors.isNotEmpty || parsedMoney == null || parsedDate == null) {
      return ImportLineValidation<Expense>(
        lineNumber: rawRow.lineNumber,
        rawValues: values,
        errors: errors,
        warnings: warnings,
        originalId: originalId,
        deduplicationFingerprint: fingerprint,
        status: ImportRowStatus.invalid,
      );
    }

    final expense = Expense.withMoney(
      id: originalId != null && originalId.isNotEmpty ? originalId : null,
      money: parsedMoney,
      date: parsedDate,
      categoryId: resolvedCategoryId,
      motivation: values['motivation'],
      location: values['location'],
      isIncome: isIncome,
      recurringExpenseId: recurringExpenseId,
      installmentGroupId: installmentGroupId,
    );

    return ImportLineValidation<Expense>(
      lineNumber: rawRow.lineNumber,
      rawValues: values,
      parsedItem: expense,
      errors: const [],
      warnings: warnings,
      originalId: originalId,
      deduplicationFingerprint: fingerprint,
      status: warnings.isNotEmpty ? ImportRowStatus.warning : ImportRowStatus.valid,
    );
  }

  static ImportLineValidation<Credential> validateCredentialRow({
    required RawCsvRow rawRow,
    required int occurrenceIndex,
    String? defaultFolderId,
  }) {
    final values = rawRow.values;
    final List<String> errors = [];
    final List<String> warnings = [];

    if (rawRow.hasError) {
      errors.add(rawRow.parseError!);
      return ImportLineValidation<Credential>(
        lineNumber: rawRow.lineNumber,
        rawValues: values,
        errors: errors,
        deduplicationFingerprint: generateRowFingerprint(
          type: 'credential',
          normalizedFields: values,
          occurrenceIndex: occurrenceIndex,
        ),
        status: ImportRowStatus.invalid,
      );
    }

    final location = values['location']?.trim() ?? '';
    if (location.isEmpty) {
      errors.add('Local / Serviço é obrigatório (não é permitido preencher com "N/A" inventado).');
    }

    final login = values['login']?.trim() ?? '';
    if (login.isEmpty) {
      errors.add('Login / Usuário é obrigatório (não é permitido preencher com "N/A" inventado).');
    }

    final password = values['password'] ?? '';
    if (password.isEmpty) {
      errors.add('Senha é obrigatória para importação de credencial.');
    }

    final explicitFolderId = values['folderid'];
    final rawFolderSnake = values['folder_id'];
    String? resolvedFolderId = explicitFolderId;

    if (explicitFolderId != null &&
        rawFolderSnake != null &&
        explicitFolderId.trim() != rawFolderSnake.trim()) {
      errors.add(
        'Inconsistência na linha: colunas "folderId" e "folder_id" possuem valores diferentes.',
      );
    } else if (resolvedFolderId == null || resolvedFolderId.trim().isEmpty) {
      resolvedFolderId = defaultFolderId;
    }

    final originalId = values['id'];
    final fingerprint = generateRowFingerprint(
      type: 'credential',
      normalizedFields: values,
      occurrenceIndex: occurrenceIndex,
    );

    if (errors.isNotEmpty) {
      return ImportLineValidation<Credential>(
        lineNumber: rawRow.lineNumber,
        rawValues: values,
        errors: errors,
        warnings: warnings,
        originalId: originalId,
        deduplicationFingerprint: fingerprint,
        status: ImportRowStatus.invalid,
      );
    }

    final credential = Credential(
      id: originalId != null && originalId.isNotEmpty ? originalId : null,
      location: location,
      login: login,
      encryptedPassword: password,
      email: values['email'],
      phoneNumber: values['phone_number'] ?? values['phone'],
      notes: values['notes'],
      folderId: resolvedFolderId,
    );

    return ImportLineValidation<Credential>(
      lineNumber: rawRow.lineNumber,
      rawValues: values,
      parsedItem: credential,
      errors: const [],
      warnings: warnings,
      originalId: originalId,
      deduplicationFingerprint: fingerprint,
      status: warnings.isNotEmpty ? ImportRowStatus.warning : ImportRowStatus.valid,
    );
  }

  static ImportLineValidation<RecurringExpense> validateRecurringRow({
    required RawCsvRow rawRow,
    required int occurrenceIndex,
  }) {
    final values = rawRow.values;
    final List<String> errors = [];
    final List<String> warnings = [];

    if (rawRow.hasError) {
      errors.add(rawRow.parseError!);
      return ImportLineValidation<RecurringExpense>(
        lineNumber: rawRow.lineNumber,
        rawValues: values,
        errors: errors,
        deduplicationFingerprint: generateRowFingerprint(
          type: 'recurring',
          normalizedFields: values,
          occurrenceIndex: occurrenceIndex,
        ),
        status: ImportRowStatus.invalid,
      );
    }

    final rawFreq = values['frequency']?.toLowerCase().trim() ?? '';
    RecurrenceFrequency? frequency;
    if (rawFreq.contains('diar') || rawFreq == 'daily') {
      frequency = RecurrenceFrequency.daily;
    } else if (rawFreq.contains('seman') || rawFreq == 'weekly') {
      frequency = RecurrenceFrequency.weekly;
    } else if (rawFreq.contains('mens') || rawFreq == 'monthly') {
      frequency = RecurrenceFrequency.monthly;
    } else {
      errors.add('Frequência desconhecida "$rawFreq". Apenas diária, semanal e mensal são suportadas.');
    }

    final rawAmount = values['amount'];
    Money? parsedMoney;
    if (rawAmount == null || rawAmount.trim().isEmpty) {
      errors.add('Valor da despesa recorrente não pode ser vazio.');
    } else {
      try {
        parsedMoney = MoneyParser.parse(rawAmount);
      } catch (e) {
        errors.add('Valor monetário inválido para recorrência: "$rawAmount".');
      }
    }

    final rawStartDate = values['startdate'];
    DateTime? startDate;
    if (rawStartDate == null || rawStartDate.trim().isEmpty) {
      errors.add('Data de início é obrigatória para despesa recorrente.');
    } else {
      startDate = parseStrictDate(rawStartDate);
      if (startDate == null) {
        errors.add('Data de início inválida "$rawStartDate".');
      }
    }

    final rawEndDate = values['enddate'];
    DateTime? endDate;
    if (rawEndDate != null && rawEndDate.trim().isNotEmpty) {
      endDate = parseStrictDate(rawEndDate);
      if (endDate == null) {
        errors.add('Data de término inválida "$rawEndDate".');
      }
    }

    final originalId = values['id'];
    final fingerprint = generateRowFingerprint(
      type: 'recurring',
      normalizedFields: values,
      occurrenceIndex: occurrenceIndex,
    );

    if (errors.isNotEmpty || frequency == null || parsedMoney == null || startDate == null) {
      return ImportLineValidation<RecurringExpense>(
        lineNumber: rawRow.lineNumber,
        rawValues: values,
        errors: errors,
        warnings: warnings,
        originalId: originalId,
        deduplicationFingerprint: fingerprint,
        status: ImportRowStatus.invalid,
      );
    }

    warnings.add(
      'Regra recorrente importada como rascunho pausado para conferência de agenda e cursor.',
    );

    final rule = RecurringExpense.withMoney(
      id: originalId != null && originalId.isNotEmpty ? originalId : null,
      money: parsedMoney,
      frequency: frequency,
      startDate: startDate,
      endDate: endDate,
      categoryId: values['categoryid'],
      motivation: values['motivation'],
      location: values['location'],
      engineVersion: 1,
      scheduleVersion: 1,
      generationState: 'paused',
    );

    return ImportLineValidation<RecurringExpense>(
      lineNumber: rawRow.lineNumber,
      rawValues: values,
      parsedItem: rule,
      errors: const [],
      warnings: warnings,
      originalId: originalId,
      deduplicationFingerprint: fingerprint,
      status: ImportRowStatus.warning,
    );
  }
}
