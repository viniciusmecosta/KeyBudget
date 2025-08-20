import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

enum ImportResult { success, failure, noFileSelected }

class DatabaseManagementService {
  Future<String> get _dbPath async {
    final dbFolder = await getApplicationDocumentsDirectory();
    return p.join(dbFolder.path, 'keybudget.db');
  }

  Future<bool> exportDatabase() async {
    try {
      if (await Permission.storage.request().isGranted) {
        final path = await _dbPath;
        File dbFile = File(path);

        if (await dbFile.exists()) {
          Uint8List bytes = await dbFile.readAsBytes();
          await FileSaver.instance.saveFile(
            name: 'keybudget_backup_${DateTime.now().toIso8601String()}',
            bytes: bytes,
            fileExtension: 'db',
            mimeType: MimeType.other,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<ImportResult> importDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result != null && result.files.single.path != null) {
        final path = await _dbPath;
        final currentDbFile = File(path);
        final backupFile = File('$path.bak');

        if (await currentDbFile.exists()) {
          await currentDbFile.rename(backupFile.path);
        }

        final newDbFile = File(result.files.single.path!);
        await newDbFile.copy(path);

        final dbPassword = dotenv.env['DB_PASSWORD'];
        try {
          await openDatabase(path, password: dbPassword);
          if (await backupFile.exists()) {
            await backupFile.delete();
          }
          return ImportResult.success;
        } catch (e) {
          if (await backupFile.exists()) {
            await backupFile.rename(path);
          }
          return ImportResult.failure;
        }
      } else {
        return ImportResult.noFileSelected;
      }
    } catch (e) {
      return ImportResult.failure;
    }
  }
}
