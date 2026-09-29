import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:key_budget/core/import_export/automatic_backup_service.dart';
import 'package:key_budget/core/import_export/backup_manifest.dart';
import 'package:key_budget/core/import_export/backup_service.dart';
import 'package:key_budget/core/services/drive_service.dart';

class _MemoryStorage extends Fake implements FlutterSecureStorage {
  final values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

class _OfflineDrive extends DriveService {
  @override
  Future<drive.File?> uploadFile(
    File file,
    void Function(int, int) onProgress, {
    String? serverClientId,
    bool isBackup = false,
    bool allowInteractive = true,
  }) async => null;
}

void main() {
  test(
    'daily automatic backups keep only the selected local history',
    () async {
      final directory = await Directory.systemTemp.createTemp('keybudget-auto');
      addTearDown(() => directory.delete(recursive: true));
      final storage = _MemoryStorage();
      var now = DateTime(2026, 10, 1, 10);
      var created = 0;
      final service = AutomaticBackupService(
        storage: storage,
        driveService: _OfflineDrive(),
        documentsDirectory: () async => directory,
        currentUserId: () => 'user',
        now: () => now,
        createBackup: (userId, password) async {
          created++;
          final completeness = BackupCompleteness(isComplete: true);
          return BackupResultData(
            envelopeBytes: Uint8List.fromList([1, 2, created]),
            completeness: completeness,
            manifest: BackupManifest(
              appVersion: 'test',
              createdAt: now,
              backupId: '$created',
              originUid: userId,
              modules: const [],
              counts: const {},
              hashes: const {},
              completeness: completeness,
            ),
          );
        },
      );

      await service.saveSettings(
        userId: 'user',
        interval: AutomaticBackupInterval.daily,
        retention: 2,
        password: 'secret123',
      );
      await service.runIfDue('user');
      await service.runIfDue('user');
      expect(created, 1);

      now = now.add(const Duration(days: 1));
      await service.runIfDue('user');
      now = now.add(const Duration(days: 1));
      await service.runIfDue('user');

      expect(created, 3);
      expect((await service.listLocalHistory('user')).length, 2);
      final settings = await service.readSettings('user');
      expect(settings.lastLocalCompletion, now);
      expect(settings.lastDriveCompletion, isNull);
      expect(settings.lastError, contains('Drive pendente'));
    },
  );

  test('disabled backup removes stored password', () async {
    final storage = _MemoryStorage();
    final service = AutomaticBackupService(
      storage: storage,
      currentUserId: () => 'user',
    );
    await service.saveSettings(
      userId: 'user',
      interval: AutomaticBackupInterval.weekly,
      retention: 3,
      password: 'secret123',
    );
    await service.saveSettings(
      userId: 'user',
      interval: AutomaticBackupInterval.off,
      retention: 3,
    );
    expect(
      storage.values.keys.where((key) => key.endsWith('.password')),
      isEmpty,
    );
    expect(
      (await service.readSettings('user')).interval,
      AutomaticBackupInterval.off,
    );
  });
}
