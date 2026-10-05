import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SensitiveExportCache {
  static Future<void> clearExpired() async {
    try {
      final directory = await getTemporaryDirectory();
      final threshold = DateTime.now().subtract(const Duration(hours: 1));
      await for (final entry in directory.list()) {
        if (entry is! File) continue;
        final name = p.basename(entry.path);
        if (!name.startsWith('keybudget_credentials_')) continue;
        if (!name.endsWith('.csv') && !name.endsWith('.pdf')) continue;
        final stat = await entry.stat();
        if (stat.modified.isBefore(threshold)) {
          await entry.delete();
        }
      }
    } catch (_) {
      return;
    }
  }
}
