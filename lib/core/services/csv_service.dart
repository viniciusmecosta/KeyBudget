import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvService {
  Future<bool> exportCredentials(
      BuildContext context, List<Credential> credentials) async {
    List<List<dynamic>> rows = [
      ['location', 'login', 'email', 'phone_number', 'notes', 'password']
    ];
    for (var cred in credentials) {
      rows.add([
        cred.location,
        cred.login,
        cred.email ?? '',
        cred.phoneNumber ?? '',
        cred.notes ?? '',
        cred.encryptedPassword
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    return _saveCsvFile(context, 'keybudget_credentials', csv);
  }

  Future<bool> exportExpenses(
      BuildContext context, List<Expense> expenses) async {
    List<List<dynamic>> rows = [
      ['date', 'amount', 'categoryId', 'motivation', 'location']
    ];
    for (var exp in expenses) {
      rows.add([
        exp.date.toIso8601String(),
        exp.amount,
        exp.categoryId ?? '',
        exp.motivation ?? '',
        exp.location ?? ''
      ]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    return _saveCsvFile(context, 'keybudget_expenses', csv);
  }

  Future<File?> _pickCsvFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> importCsv() async {
    final file = await _pickCsvFile();
    if (file == null) return null;
    final input = file.openRead();
    final fields = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();
    if (fields.length < 2) return [];
    final headers = fields.first.map((e) => e.toString()).toList();
    List<Map<String, dynamic>> result = [];
    for (var i = 1; i < fields.length; i++) {
      var row = fields[i];
      Map<String, dynamic> mappedRow = {};
      for (var j = 0; j < headers.length; j++) {
        mappedRow[headers[j]] = row[j];
      }
      result.add(mappedRow);
    }
    return result;
  }

  Future<bool> _saveCsvFile(
      BuildContext context, String baseName, String data) async {
    try {
      final fileName =
          '${baseName}_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(utf8.encode(data));
      if (!context.mounted) return false;
      final params = ShareParams(
          files: [XFile(filePath)], text: 'Exportação CSV do KeyBudget');
      await SharePlus.instance.share(params);
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      SnackbarService.showError(context, 'Failed to save file: $e',
          title: 'Error Exporting CSV');
      return false;
    }
  }

  Future<bool> exportAnalysisCsv(
      BuildContext context, AnalysisViewModel viewModel) async {
    List<List<dynamic>> rows = [
      ['Month', 'Total Expenses']
    ];
    final data = viewModel.lastNMonthsData;
    for (var entry in data.entries) {
      rows.add([entry.key, entry.value]);
    }
    rows.add([]);
    rows.add(['Category', 'Total Expenses']);
    final categoryData = viewModel.expensesByCategoryForSelectedMonth;
    for (var entry in categoryData.entries) {
      rows.add([entry.key.name, entry.value]);
    }
    String csv = const ListToCsvConverter().convert(rows);
    return _saveCsvFile(context, 'keybudget_analysis', csv);
  }
}
