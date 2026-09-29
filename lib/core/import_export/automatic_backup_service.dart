import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:key_budget/core/import_export/backup_service.dart';
import 'package:key_budget/core/import_export/raw_storage.dart';
import 'package:key_budget/core/operations/session_context.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:path_provider/path_provider.dart';

enum AutomaticBackupInterval { off, daily, weekly }

class AutomaticBackupSettings {
  final AutomaticBackupInterval interval;
  final int retention;
  final DateTime? lastLocalCompletion;
  final DateTime? lastDriveCompletion;
  final String? lastError;

  const AutomaticBackupSettings({
    required this.interval,
    required this.retention,
    this.lastLocalCompletion,
    this.lastDriveCompletion,
    this.lastError,
  });

  bool isDue(DateTime now) {
    if (interval == AutomaticBackupInterval.off) return false;
    if (lastLocalCompletion == null) return true;
    final gap = interval == AutomaticBackupInterval.daily
        ? const Duration(days: 1)
        : const Duration(days: 7);
    return !now.isBefore(lastLocalCompletion!.add(gap));
  }
}

class AutomaticBackupFile {
  final File file;
  final DateTime modifiedAt;
  final int sizeBytes;

  const AutomaticBackupFile({
    required this.file,
    required this.modifiedAt,
    required this.sizeBytes,
  });
}

class AutomaticBackupService {
  final FlutterSecureStorage _storage;
  final DriveService _driveService;
  final Future<Directory> Function() _documentsDirectory;
  final String? Function() _currentUserId;
  final DateTime Function() _now;
  final Future<BackupResultData?> Function(String, String) _createBackup;

  static final Set<String> _running = {};

  AutomaticBackupService({
    FlutterSecureStorage? storage,
    DriveService? driveService,
    Future<Directory> Function()? documentsDirectory,
    String? Function()? currentUserId,
    DateTime Function()? now,
    Future<BackupResultData?> Function(String, String)? createBackup,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _driveService = driveService ?? DriveService(),
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _currentUserId =
           currentUserId ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _now = now ?? DateTime.now,
       _createBackup = createBackup ?? _createVerifiedBackup;

  String _key(String userId, String field) => 'automatic_backup.$userId.$field';

  static Future<BackupResultData?> _createVerifiedBackup(
    String userId,
    String password,
  ) async {
    final result = await BackupService(
      rawReader: FirestoreRawStorage(),
      sessionContext: SessionContext(userId: userId, sessionGeneration: 1),
      encryptionService: EncryptionService(),
      driveService: DriveService(),
    ).createBackup(password: password);
    if (!result.isSuccess || result.data?.completeness.isComplete != true) {
      return null;
    }
    return result.data;
  }

  Future<AutomaticBackupSettings> readSettings(String userId) async {
    final values = await Future.wait([
      _storage.read(key: _key(userId, 'interval')),
      _storage.read(key: _key(userId, 'retention')),
      _storage.read(key: _key(userId, 'last_local')),
      _storage.read(key: _key(userId, 'last_drive')),
      _storage.read(key: _key(userId, 'last_error')),
    ]);
    final interval = AutomaticBackupInterval.values.firstWhere(
      (value) => value.name == values[0],
      orElse: () => AutomaticBackupInterval.off,
    );
    DateTime? parseDate(String? value) =>
        value == null ? null : DateTime.tryParse(value);
    return AutomaticBackupSettings(
      interval: interval,
      retention: (int.tryParse(values[1] ?? '') ?? 7).clamp(1, 30),
      lastLocalCompletion: parseDate(values[2]),
      lastDriveCompletion: parseDate(values[3]),
      lastError: values[4],
    );
  }

  Future<void> saveSettings({
    required String userId,
    required AutomaticBackupInterval interval,
    required int retention,
    String? password,
  }) async {
    if (retention < 1 || retention > 30) {
      throw ArgumentError.value(retention, 'retention');
    }
    if (interval != AutomaticBackupInterval.off) {
      if (password != null && password.length < 6) {
        throw ArgumentError('A senha deve ter pelo menos 6 caracteres.');
      }
      final savedPassword = await _storage.read(key: _key(userId, 'password'));
      if (password == null && savedPassword == null) {
        throw ArgumentError('Informe uma senha para o backup automático.');
      }
      if (password != null) {
        await _storage.write(key: _key(userId, 'password'), value: password);
      }
    } else {
      await _storage.delete(key: _key(userId, 'password'));
    }
    await _storage.write(key: _key(userId, 'interval'), value: interval.name);
    await _storage.write(key: _key(userId, 'retention'), value: '$retention');
  }

  Future<List<AutomaticBackupFile>> listLocalHistory(String userId) async {
    final directory = await _backupDirectory(userId);
    if (!await directory.exists()) return [];
    final files = await directory
        .list()
        .where(
          (entry) =>
              entry is File &&
              entry.path.endsWith('.kbudget') &&
              entry.uri.pathSegments.last.startsWith('auto_'),
        )
        .cast<File>()
        .toList();
    final history = <AutomaticBackupFile>[];
    for (final file in files) {
      final stat = await file.stat();
      history.add(
        AutomaticBackupFile(
          file: file,
          modifiedAt: stat.modified,
          sizeBytes: stat.size,
        ),
      );
    }
    history.sort(
      (first, second) => second.modifiedAt.compareTo(first.modifiedAt),
    );
    return history;
  }

  Future<Directory> _backupDirectory(String userId) async {
    final root = await _documentsDirectory();
    return Directory('${root.path}/automatic_backups/$userId');
  }

  Future<bool> runIfDue(
    String userId, {
    bool allowInteractive = false,
    bool force = false,
  }) async {
    if (_currentUserId() != userId || !_running.add(userId)) return false;
    try {
      final settings = await readSettings(userId);
      if (settings.interval == AutomaticBackupInterval.off) return false;
      final now = _now();
      File? latestFile;
      if (force || settings.isDue(now)) {
        final password = await _storage.read(key: _key(userId, 'password'));
        if (password == null) return false;
        final result = await _createBackup(userId, password);
        if (result == null || _currentUserId() != userId) {
          await _storage.write(
            key: _key(userId, 'last_error'),
            value: 'Não foi possível concluir e verificar o backup.',
          );
          return false;
        }
        final directory = await _backupDirectory(userId);
        await directory.create(recursive: true);
        latestFile = File(
          '${directory.path}/auto_${now.millisecondsSinceEpoch}_${result.manifest.backupId}.kbudget',
        );
        await latestFile.writeAsBytes(result.envelopeBytes, flush: true);
        await _storage.write(
          key: _key(userId, 'last_local'),
          value: now.toIso8601String(),
        );
        await _storage.delete(key: _key(userId, 'last_error'));
        await _pruneLocal(userId, settings.retention);
      } else if (settings.lastDriveCompletion == null ||
          settings.lastDriveCompletion!.isBefore(
            settings.lastLocalCompletion ?? now,
          )) {
        final history = await listLocalHistory(userId);
        if (history.isNotEmpty) latestFile = history.first.file;
      }

      if (latestFile == null || _currentUserId() != userId) return false;
      final uploaded = await _driveService.uploadFile(
        latestFile,
        (_, _) {},
        isBackup: true,
        allowInteractive: allowInteractive,
      );
      if (uploaded?.id == null) {
        await _storage.write(
          key: _key(userId, 'last_error'),
          value: 'Cópia local concluída; envio ao Drive pendente.',
        );
        return false;
      }
      await _storage.write(
        key: _key(userId, 'last_drive'),
        value: _now().toIso8601String(),
      );
      await _storage.delete(key: _key(userId, 'last_error'));
      await _pruneDrive(settings.retention);
      return true;
    } on DriveAuthorizationCancelled {
      return false;
    } catch (_) {
      await _storage.write(
        key: _key(userId, 'last_error'),
        value: 'Falha no backup automático. Tente novamente.',
      );
      return false;
    } finally {
      _running.remove(userId);
    }
  }

  Future<void> _pruneLocal(String userId, int retention) async {
    final history = await listLocalHistory(userId);
    for (final item in history.skip(retention)) {
      await item.file.delete();
    }
  }

  Future<void> _pruneDrive(int retention) async {
    final files = await _driveService.listBackupFiles(allowInteractive: false);
    final automatic =
        files.where((file) => file.name.startsWith('auto_')).toList()..sort(
          (first, second) =>
              (second.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                    first.modifiedTime ??
                        DateTime.fromMillisecondsSinceEpoch(0),
                  ),
        );
    for (final file in automatic.skip(retention)) {
      await _driveService.deleteFile(file.id, allowInteractive: false);
    }
  }
}
