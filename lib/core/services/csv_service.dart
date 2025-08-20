import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/expense_category.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:permission_handler/permission_handler.dart';

class CsvService {
  Future<bool> exportCredentials(List<Credential> credentials) async {
    List<List<dynamic>> rows = [];
    rows.add(
        ['location', 'login', 'email', 'phone_number', 'notes', 'password']);
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
    return _saveCsvFile('keybudget_credentials', csv);
  }

  Future<bool> exportExpenses(List<Expense> expenses) async {
    List<List<dynamic>> rows = [];
    rows.add(['date', 'amount', 'category', 'motivation', 'location']);
    for (var exp in expenses) {
      rows.add([
        exp.date.toIso8601String(),
        exp.amount,
        exp.category?.displayName ?? '',
        exp.motivation ?? '',
        exp.location ?? ''
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    return _saveCsvFile('keybudget_expenses', csv);
  }

  Future<File?> _pickCsvFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
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

  Future<bool> _saveCsvFile(String baseName, String data) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (status.isDenied) {
          final result = await Permission.storage.request();
          if (result.isDenied) {
            return false;
          }
        }
      }

      final bytes = utf8.encode(data);
      await FileSaver.instance.saveFile(
        name: '${baseName}_${DateTime.now().toIso8601String()}',
        bytes: bytes,
        fileExtension: 'csv',
        mimeType: MimeType.csv,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}