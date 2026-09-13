import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/core/operations/session_context.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:path_provider/path_provider.dart';

import 'backup_codec.dart';
import 'backup_crypto.dart';
import 'backup_manifest.dart';
import 'raw_storage.dart';

class BackupResultData {
  final Uint8List envelopeBytes;
  final BackupManifest manifest;
  final BackupCompleteness completeness;
  final File? localFile;

  const BackupResultData({
    required this.envelopeBytes,
    required this.manifest,
    required this.completeness,
    this.localFile,
  });
}

class BackupService {
  final RawStorageReader rawReader;
  final SessionContext sessionContext;
  final EncryptionService? encryptionService;
  final DriveService? driveService;
  final AppClock clock;

  BackupService({
    required this.rawReader,
    required this.sessionContext,
    this.encryptionService,
    this.driveService,
    this.clock = const SystemAppClock(),
  });

  static const List<String> allAvailableModules = [
    'categories',
    'folders',
    'expenses',
    'recurring_expenses',
    'recurrence_occurrences',
    'credentials',
    'suppliers',
    'documents',
    'profile',
  ];

  Future<OperationResult<BackupResultData>> createBackup({
    required String password,
    List<String>? selectedModules,
    void Function(String status, double progress)? onProgress,
  }) async {
    if (!sessionContext.isValid) {
      return OperationResult.failed(
        safeError: 'Sessão de usuário inválida para realizar backup.',
      );
    }

    if (password.length < 6) {
      return OperationResult.failed(
        safeError: 'A senha do backup deve ter pelo menos 6 caracteres.',
      );
    }

    final uid = sessionContext.userId;

    final modules = _expandDependencies(selectedModules ?? allAvailableModules);
    onProgress?.call('Iniciando inventário das coleções...', 0.1);

    final read1 = await _captureCollections(uid, modules);
    onProgress?.call('Verificando estabilidade dos dados capturados...', 0.25);
    final read2 = await _captureCollections(uid, modules);

    final conflict = _detectReadDrift(read1, read2);
    if (conflict != null) {
      return OperationResult.conflict(
        message: 'Detectada alteração concorrente durante a captura de dados. Tente novamente.',
        affectedIds: conflict,
      );
    }

    final capturedData = read2;

    final missingAttachments = <String>[];
    final undecryptableCredentials = <String>[];
    final warnings = <String>[];

    final credentialRecords = <BackupRecord>[];
    final rawCredentials = capturedData['credentials'] ?? [];
    for (final raw in rawCredentials) {
      final id = (raw['id'] ?? '').toString();
      final encryptedPass = raw['encrypted_password']?.toString();
      String? portablePass;

      final enc = encryptionService;
      if (encryptedPass != null && enc != null) {
        try {
          final decrypted = enc.decryptData(encryptedPass);
          if (decrypted != 'ERRO_DECRIPT') {
            portablePass = decrypted;
          } else {
            undecryptableCredentials.add(id);
          }
        } catch (_) {
          undecryptableCredentials.add(id);
        }
      }

      credentialRecords.add(
        BackupRecord(
          id: id,
          data: raw,
          portablePassword: portablePass,
        ),
      );
    }

    onProgress?.call('Processando anexos e arquivos...', 0.4);
    final attachmentMetas = <BackupAttachmentMeta>[];
    final attachmentFiles = <String, List<int>>{};

    final rawDocuments = capturedData['documents'] ?? [];
    for (final doc in rawDocuments) {
      final attachments = doc['attachments'] as List<dynamic>? ?? [];
      for (final att in attachments) {
        if (att is Map) {
          final driveId = att['driveId']?.toString();
          final name = att['name']?.toString() ?? 'anexo';
          final type = att['type']?.toString() ?? 'application/octet-stream';

          if (driveId != null && driveId.isNotEmpty) {
            final internalId = 'att_${sha256.convert(utf8.encode(driveId)).toString().substring(0, 12)}';
            if (!attachmentFiles.containsKey(internalId)) {
              List<int>? bytes;
              if (driveService != null) {
                try {
                  bytes = await driveService!.downloadFile(driveId);
                } catch (_) {
                  bytes = null;
                }
              }

              if (bytes != null) {
                final hash = sha256.convert(bytes).toString();
                attachmentFiles['attachments/$internalId'] = bytes;
                attachmentMetas.add(
                  BackupAttachmentMeta(
                    internalId: internalId,
                    originalDriveId: driveId,
                    fileName: name,
                    mimeType: type,
                    sizeBytes: bytes.length,
                    sha256: hash,
                  ),
                );
              } else {
                missingAttachments.add('Documento "${doc['documentName'] ?? doc['id']}": $name');
              }
            }
          }
        }
      }
    }

    onProgress?.call('Serializando registros canônicos...', 0.6);
    final filesToPack = <String, List<int>>{};
    final counts = <String, int>{};
    final hashes = <String, String>{};

    for (final mod in modules) {
      if (mod == 'credentials') {
        final jsonStr = BackupCodec.encodeRecords(credentialRecords);
        final bytes = utf8.encode(jsonStr);
        final filePath = 'records/credentials.json';
        filesToPack[filePath] = bytes;
        counts['credentials'] = credentialRecords.length;
        hashes[filePath] = sha256.convert(bytes).toString();
      } else {
        final recordsList = (capturedData[mod] ?? [])
            .map((raw) => BackupRecord(id: (raw['id'] ?? '').toString(), data: raw))
            .toList();
        final jsonStr = BackupCodec.encodeRecords(recordsList);
        final bytes = utf8.encode(jsonStr);
        final filePath = 'records/$mod.json';
        filesToPack[filePath] = bytes;
        counts[mod] = recordsList.length;
        hashes[filePath] = sha256.convert(bytes).toString();
      }
    }

    for (final entry in attachmentFiles.entries) {
      filesToPack[entry.key] = entry.value;
      hashes[entry.key] = sha256.convert(entry.value).toString();
    }

    final isComplete = missingAttachments.isEmpty && undecryptableCredentials.isEmpty;
    final completeness = BackupCompleteness(
      isComplete: isComplete,
      missingAttachments: missingAttachments,
      undecryptableCredentials: undecryptableCredentials,
      warnings: warnings,
    );

    final backupId = 'bkp_${clock.now().millisecondsSinceEpoch}_${uid.substring(0, uid.length.clamp(0, 6))}';
    final manifest = BackupManifest(
      formatVersion: 1,
      appVersion: '1.1.2',
      createdAt: clock.now().toUtc(),
      backupId: backupId,
      originUid: uid,
      modules: modules,
      counts: counts,
      hashes: hashes,
      attachments: attachmentMetas,
      completeness: completeness,
    );

    final manifestBytes = utf8.encode(manifest.toJsonString());
    filesToPack['manifest.json'] = manifestBytes;

    onProgress?.call('Criptografando pacote com AES-256-GCM...', 0.75);
    final zipBytes = BackupCrypto.packArchive(filesToPack);
    final envelopeBytes = BackupCrypto.encryptEnvelope(
      payload: zipBytes,
      password: password,
    );

    onProgress?.call('Realizando auto-verificação de integridade...', 0.9);
    try {
      final decryptedZip = BackupCrypto.decryptEnvelope(
        envelope: envelopeBytes,
        password: password,
      );
      final unpacked = BackupCrypto.unpackArchive(decryptedZip);
      if (!unpacked.containsKey('manifest.json')) {
        throw const BackupCryptoException('Auto-verificação falhou: manifesto ausente.');
      }
      final verifiedManifest = BackupManifest.fromJsonString(
        utf8.decode(unpacked['manifest.json']!),
      );

      for (final hashEntry in verifiedManifest.hashes.entries) {
        final content = unpacked[hashEntry.key];
        if (content == null) {
          throw BackupCryptoException('Arquivo verificado ausente: ${hashEntry.key}');
        }
        final calculated = sha256.convert(content).toString();
        if (calculated != hashEntry.value) {
          throw BackupCryptoException('Hash divergente em ${hashEntry.key}');
        }
      }
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Falha na auto-verificação de integridade do backup gerado: $e',
      );
    }

    File? savedFile;
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/backup_$backupId.kbudget';
      savedFile = File(filePath);
      await savedFile.writeAsBytes(envelopeBytes, flush: true);
    } catch (_) {

    }

    onProgress?.call('Backup concluído com sucesso!', 1.0);

    final totalCount = counts.values.fold<int>(0, (sum, count) => sum + count);

    return OperationResult.completed(
      data: BackupResultData(
        envelopeBytes: envelopeBytes,
        manifest: manifest,
        completeness: completeness,
        localFile: savedFile,
      ),
      count: totalCount,
    );
  }

  List<String> _expandDependencies(List<String> selected) {
    final modules = selected.toSet();
    if (modules.contains('expenses') || modules.contains('recurring_expenses')) {
      modules.add('categories');
    }
    if (modules.contains('recurring_expenses')) {
      modules.add('recurrence_occurrences');
    }
    if (modules.contains('credentials')) {
      modules.add('folders');
    }
    return modules.toList();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _captureCollections(
    String uid,
    List<String> modules,
  ) async {
    final result = <String, List<Map<String, dynamic>>>{};

    for (final mod in modules) {
      if (mod == 'profile') {
        final profileDoc = await rawReader.getDocument('users/$uid');
        result['profile'] = profileDoc != null ? [profileDoc] : [];
      } else {
        final docs = await rawReader.getCollection('users/$uid/$mod');
        result[mod] = docs;
      }
    }

    return result;
  }

  List<String>? _detectReadDrift(
    Map<String, List<Map<String, dynamic>>> read1,
    Map<String, List<Map<String, dynamic>>> read2,
  ) {
    final conflictingIds = <String>[];

    for (final collection in read1.keys) {
      final list1 = read1[collection] ?? [];
      final list2 = read2[collection] ?? [];

      final map1 = {for (final d in list1) (d['id'] ?? '').toString(): d};
      final map2 = {for (final d in list2) (d['id'] ?? '').toString(): d};

      if (map1.length != map2.length) {
        conflictingIds.add(collection);
        continue;
      }

      for (final id in map1.keys) {
        if (!map2.containsKey(id)) {
          conflictingIds.add('$collection/$id');
        } else {
          final digest1 = BackupCodec.computeCanonicalDigest(map1[id]!);
          final digest2 = BackupCodec.computeCanonicalDigest(map2[id]!);
          if (digest1 != digest2) {
            conflictingIds.add('$collection/$id');
          }
        }
      }
    }

    return conflictingIds.isNotEmpty ? conflictingIds : null;
  }
}
