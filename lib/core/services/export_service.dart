import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ExportService {
  Future<bool> exportDatabase() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbPath = p.join(dbFolder.path, 'keybudget.db');
      File dbFile = File(dbPath);

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
      return false;
    } catch (e) {
      return false;
    }
  }
}
