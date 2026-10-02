import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/core/operations/session_context.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:path_provider/path_provider.dart';

import 'backup_codec.dart';
import 'backup_crypto.dart';
import 'backup_manifest.dart';
import 'import_plan.dart';
import 'operation_journal.dart';
import 'raw_storage.dart';

class RestoreSummary {
  final int createdCount;
  final int skippedCount;
  final int replacedCount;
  final int uploadedAttachmentsCount;
  final List<String> warnings;

  const RestoreSummary({
    required this.createdCount,
    required this.skippedCount,
    required this.replacedCount,
    required this.uploadedAttachmentsCount,
    this.warnings = const [],
  });
}

class RestoreService {
  final RawStorageReader rawReader;
  final RawStorageWriter rawWriter;
  final SessionContext sessionContext;
  final EncryptionService? encryptionService;
  final DriveService? driveService;
  final AppClock clock;
  final OperationJournal? customJournal;
  final FlutterSecureStorage? secureStorage;

  RestoreService({
    required this.rawReader,
    required this.rawWriter,
    required this.sessionContext,
    this.encryptionService,
    this.driveService,
    this.clock = const SystemAppClock(),
    this.customJournal,
    this.secureStorage,
  });

  Future<OperationResult<ImportPlan>> previewRestore({
    required Uint8List backupBytes,
    required String password,
  }) async {
    if (!sessionContext.isValid) {
      return OperationResult.failed(
        safeError: 'Sessão de usuário inválida para restauração.',
      );
    }

    final targetUid = sessionContext.userId;

    final Uint8List zipBytes;
    try {
      zipBytes = await Isolate.run(
        () => BackupCrypto.decryptEnvelope(
          envelope: backupBytes,
          password: password,
        ),
      );
    } on BackupCryptoException catch (e) {
      return OperationResult.failed(safeError: e.message);
    } catch (e) {
      return OperationResult.failed(
        safeError:
            'Não foi possível abrir o backup. Confira a senha e o arquivo.',
      );
    }

    final Map<String, List<int>> unpacked;
    try {
      unpacked = await Isolate.run(() => BackupCrypto.unpackArchive(zipBytes));
    } on BackupSecurityException catch (e) {
      return OperationResult.failed(
        safeError: 'Violação de segurança do arquivo de backup: ${e.message}',
      );
    } catch (e) {
      return OperationResult.failed(
        safeError: 'O arquivo de backup está danificado ou incompleto.',
      );
    }

    final manifestBytes = unpacked['manifest.json'];
    if (manifestBytes == null) {
      return OperationResult.failed(
        safeError: 'Arquivo de backup inválido: manifest.json não encontrado.',
      );
    }

    final BackupManifest manifest;
    try {
      manifest = BackupManifest.fromJsonString(utf8.decode(manifestBytes));
    } catch (e) {
      return OperationResult.failed(
        safeError: 'O backup contém dados inválidos. Escolha outro arquivo.',
      );
    }

    final validationErrors = <String>[];
    final warnings = <String>[];

    if (manifest.formatVersion > BackupCrypto.currentFormatVersion) {
      validationErrors.add(
        'Versão de backup ${manifest.formatVersion} não é suportada por esta versão do app.',
      );
    }

    if (manifest.originUid != targetUid) {
      validationErrors.add(
        'Este backup pertence à conta "${manifest.originUid}". A restauração na v1 só é permitida na mesma conta de origem.',
      );
    }

    for (final entry in manifest.hashes.entries) {
      final fileData = unpacked[entry.key];
      if (fileData == null) {
        validationErrors.add('Arquivo ausente no pacote: ${entry.key}');
        continue;
      }
      final computedHash = sha256.convert(fileData).toString();
      if (computedHash != entry.value) {
        validationErrors.add(
          'Integridade violada em ${entry.key}: hash não confere.',
        );
      }
    }

    if (validationErrors.isNotEmpty) {
      return OperationResult.failed(safeError: validationErrors.join(' | '));
    }

    final items = <ImportItemPlan>[];
    final existingCategories = <String>{};
    final existingFolders = <String>{};
    final plannedCategories = <String>{};
    final plannedFolders = <String>{};

    for (final mod in manifest.modules) {
      final recordFilePath = 'records/$mod.json';
      final fileContent = unpacked[recordFilePath];
      if (fileContent == null) continue;

      final records = BackupCodec.decodeRecords(utf8.decode(fileContent));

      final List<Map<String, dynamic>> targetDocs;
      if (mod == 'profile') {
        final prof = await rawReader.getDocument('users/$targetUid');
        targetDocs = prof != null ? [prof] : [];
      } else {
        targetDocs = await rawReader.getCollection('users/$targetUid/$mod');
      }

      final targetMap = {
        for (final doc in targetDocs) (doc['id'] ?? '').toString(): doc,
      };

      if (mod == 'categories') {
        existingCategories.addAll(targetMap.keys);
      } else if (mod == 'folders') {
        existingFolders.addAll(targetMap.keys);
      }

      for (final rec in records) {
        final docId = rec.id;
        final sourceDigest = BackupCodec.computeCanonicalDigest(rec.data);
        final targetDoc = targetMap[docId];

        ImportAction action;
        String? targetDigest;

        if (targetDoc == null) {
          action = ImportAction.create;
          if (mod == 'categories') plannedCategories.add(docId);
          if (mod == 'folders') plannedFolders.add(docId);
        } else {
          targetDigest = BackupCodec.computeCanonicalDigest(targetDoc);
          if (targetDigest == sourceDigest) {
            action = ImportAction.skip;
          } else {
            action = ImportAction.conflict;
          }
        }

        String? parentCol;
        String? parentId;
        if (mod == 'expenses' || mod == 'recurring_expenses') {
          parentCol = 'categories';
          parentId = rec.data['categoryId']?.toString();
        } else if (mod == 'credentials') {
          parentCol = 'folders';
          parentId = rec.data['folder_id']?.toString();
        } else if (mod == 'documents') {
          parentCol = 'documents';
          parentId = rec.data['originalDocumentId']?.toString();
        }

        items.add(
          ImportItemPlan(
            collection: mod,
            documentId: docId,
            action: action,
            sourceData: rec.data,
            targetData: targetDoc,
            sourceDigest: sourceDigest,
            targetDigest: targetDigest,
            parentCollection: parentCol,
            parentId: parentId,
            portablePassword: rec.portablePassword,
          ),
        );
      }
    }

    final orphans = <String>[];
    for (final item in items) {
      if (item.parentId != null && item.parentId!.isNotEmpty) {
        if (item.parentCollection == 'categories') {
          final exists =
              existingCategories.contains(item.parentId) ||
              plannedCategories.contains(item.parentId);
          if (!exists) {
            orphans.add(
              '${item.collection}/${item.documentId} -> Categoria órfã "${item.parentId}"',
            );
          }
        } else if (item.parentCollection == 'folders') {
          final exists =
              existingFolders.contains(item.parentId) ||
              plannedFolders.contains(item.parentId);
          if (!exists) {
            orphans.add(
              '${item.collection}/${item.documentId} -> Pasta órfã "${item.parentId}"',
            );
          }
        }
      }
    }

    final attachmentPlans = <ImportAttachmentPlan>[];
    for (final att in manifest.attachments) {
      attachmentPlans.add(
        ImportAttachmentPlan(
          internalId: att.internalId,
          originalDriveId: att.originalDriveId,
          fileName: att.fileName,
          mimeType: att.mimeType,
          sizeBytes: att.sizeBytes,
          sha256: att.sha256,
          existsInTarget: false,
        ),
      );
    }

    final plan = ImportPlan(
      backupId: manifest.backupId,
      originUid: manifest.originUid,
      targetUid: targetUid,
      manifest: manifest,
      items: items,
      attachments: attachmentPlans,
      validationErrors: validationErrors,
      warnings: warnings,
      orphans: orphans,
    );

    return OperationResult.completed(data: plan, count: items.length);
  }

  Future<OperationResult<RestoreSummary>> executeRestore({
    required ImportPlan plan,
    required Uint8List backupBytes,
    required String password,
    void Function(String status, double progress)? onProgress,
  }) async {
    if (!plan.canExecute) {
      return OperationResult.failed(
        safeError:
            'O plano de importação contém erros impeditivos e não pode ser executado.',
      );
    }

    final uid = sessionContext.userId;

    final unpacked = await Isolate.run(
      () => BackupCrypto.unpackArchive(
        BackupCrypto.decryptEnvelope(envelope: backupBytes, password: password),
      ),
    );

    final journal =
        customJournal ??
        OperationJournal(
          operationId: 'rst_${clock.now().millisecondsSinceEpoch}',
          uid: uid,
        );

    int createdCount = 0;
    int skippedCount = 0;
    int replacedCount = 0;
    int uploadedAttachmentsCount = 0;
    final warnings = <String>[];

    try {
      journal.phase = JournalPhase.categoriesAndFolders;
      onProgress?.call('Restaurando categorias e pastas...', 0.1);

      final catFolderItems = plan.items.where(
        (i) => i.collection == 'categories' || i.collection == 'folders',
      );

      for (final item in catFolderItems) {
        if (!item.willWrite) {
          skippedCount++;
          continue;
        }
        if (journal.isItemCommitted(item.collection, item.documentId)) {
          skippedCount++;
          continue;
        }

        final path = 'users/$uid/${item.collection}/${item.documentId}';
        final beforeImage = item.targetData;
        await rawWriter.setDocument(path, item.sourceData);

        journal.recordCommit(
          item.collection,
          item.documentId,
          isCreate: item.action == ImportAction.create,
          beforeImage: beforeImage,
        );

        if (item.action == ImportAction.create) {
          createdCount++;
        } else {
          replacedCount++;
        }
      }

      journal.phase = JournalPhase.recurringRulesSuspended;
      onProgress?.call('Restaurando regras de recorrência...', 0.25);

      final recItems = plan.items.where(
        (i) => i.collection == 'recurring_expenses',
      );
      for (final item in recItems) {
        if (!item.willWrite) {
          skippedCount++;
          continue;
        }
        if (journal.isItemCommitted(item.collection, item.documentId)) {
          skippedCount++;
          continue;
        }

        final path = 'users/$uid/recurring_expenses/${item.documentId}';
        final beforeImage = item.targetData;

        final sourceCopy = Map<String, dynamic>.from(item.sourceData);
        await rawWriter.setDocument(path, sourceCopy);

        journal.recordCommit(
          item.collection,
          item.documentId,
          isCreate: item.action == ImportAction.create,
          beforeImage: beforeImage,
        );

        if (item.action == ImportAction.create) {
          createdCount++;
        } else {
          replacedCount++;
        }
      }

      journal.phase = JournalPhase.expensesCredentialsSuppliers;
      onProgress?.call(
        'Restaurando despesas, credenciais e fornecedores...',
        0.5,
      );

      final secondTierItems = plan.items.where(
        (i) =>
            i.collection == 'expenses' ||
            i.collection == 'recurrence_occurrences' ||
            i.collection == 'credentials' ||
            i.collection == 'suppliers',
      );

      for (final item in secondTierItems) {
        if (!item.willWrite) {
          skippedCount++;
          continue;
        }
        if (journal.isItemCommitted(item.collection, item.documentId)) {
          skippedCount++;
          continue;
        }

        final path = 'users/$uid/${item.collection}/${item.documentId}';
        final beforeImage = item.targetData;
        final dataToWrite = Map<String, dynamic>.from(item.sourceData);

        if (item.collection == 'credentials') {
          if (item.portablePassword != null && encryptionService != null) {
            dataToWrite['encrypted_password'] = encryptionService!.encryptData(
              item.portablePassword!,
            );
          }
        }

        await rawWriter.setDocument(path, dataToWrite);

        journal.recordCommit(
          item.collection,
          item.documentId,
          isCreate: item.action == ImportAction.create,
          beforeImage: beforeImage,
        );

        if (item.action == ImportAction.create) {
          createdCount++;
        } else {
          replacedCount++;
        }
      }

      journal.phase = JournalPhase.attachmentUploads;
      onProgress?.call('Enviando anexos para o Google Drive...', 0.7);

      for (final attPlan in plan.attachments) {
        if (!attPlan.willUpload) continue;

        if (journal.uploadedAttachmentIds.containsKey(attPlan.internalId)) {
          continue;
        }

        final fileBytes = unpacked['attachments/${attPlan.internalId}'];
        if (fileBytes != null && driveService != null) {
          try {
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/${attPlan.fileName}');
            await tempFile.writeAsBytes(fileBytes);
            final driveRes = await driveService!.uploadFile(
              tempFile,
              (p0, p1) {},
            );
            if (driveRes?.id != null) {
              journal.recordUpload(attPlan.internalId, driveRes!.id!);
              uploadedAttachmentsCount++;
            }
            if (await tempFile.exists()) {
              await tempFile.delete();
            }
          } catch (e) {
            warnings.add('Falha no upload do anexo ${attPlan.fileName}: $e');
          }
        }
      }

      journal.phase = JournalPhase.documentsAndVersions;
      onProgress?.call('Restaurando documentos e versões...', 0.85);

      final docItems = plan.items.where((i) => i.collection == 'documents');
      for (final item in docItems) {
        if (!item.willWrite) {
          skippedCount++;
          continue;
        }
        if (journal.isItemCommitted(item.collection, item.documentId)) {
          skippedCount++;
          continue;
        }

        final path = 'users/$uid/documents/${item.documentId}';
        final beforeImage = item.targetData;
        final docData = Map<String, dynamic>.from(item.sourceData);

        final attachments = docData['attachments'] as List<dynamic>?;
        if (attachments != null) {
          final updatedAttachments = <Map<String, dynamic>>[];
          for (final att in attachments) {
            if (att is Map) {
              final attMap = Map<String, dynamic>.from(att);
              final oldDriveId = attMap['driveId']?.toString();
              if (oldDriveId != null) {
                final internalId =
                    'att_${sha256.convert(utf8.encode(oldDriveId)).toString().substring(0, 12)}';
                final newDriveId = journal.uploadedAttachmentIds[internalId];
                if (newDriveId != null) {
                  attMap['driveId'] = newDriveId;
                }
              }
              updatedAttachments.add(attMap);
            }
          }
          docData['attachments'] = updatedAttachments;
        }

        await rawWriter.setDocument(path, docData);

        journal.recordCommit(
          item.collection,
          item.documentId,
          isCreate: item.action == ImportAction.create,
          beforeImage: beforeImage,
        );

        if (item.action == ImportAction.create) {
          createdCount++;
        } else {
          replacedCount++;
        }
      }

      journal.phase = JournalPhase.profilePreferences;
      final profileItems = plan.items.where((i) => i.collection == 'profile');
      for (final item in profileItems) {
        if (item.willWrite) {
          final safeData = Map<String, dynamic>.from(item.sourceData)
            ..remove('email')
            ..remove('uid');
          await rawWriter.setDocument('users/$uid', safeData, merge: true);
          journal.recordCommit('profile', item.documentId, isCreate: false);
        }
      }

      journal.phase = JournalPhase.completed;
      await journal.clearFromSecureStorage(storage: secureStorage);
      onProgress?.call('Restauração concluída com sucesso!', 1.0);

      return OperationResult.completed(
        data: RestoreSummary(
          createdCount: createdCount,
          skippedCount: skippedCount,
          replacedCount: replacedCount,
          uploadedAttachmentsCount: uploadedAttachmentsCount,
          warnings: warnings,
        ),
        count: createdCount + replacedCount,
      );
    } catch (e) {
      await journal.saveToSecureStorage(storage: secureStorage);
      return OperationResult.partial(
        totalCount: createdCount + replacedCount,
        safeError:
            'A restauração foi interrompida. O progresso foi salvo; tente continuar a restauração.',
      );
    }
  }

  Future<OperationResult<int>> rollbackOperation({
    required OperationJournal journal,
  }) async {
    final uid = journal.uid;
    int rolledBackCount = 0;

    for (final entry in journal.beforeImages.entries) {
      final parts = entry.key.split('/');
      if (parts.length >= 2) {
        final collection = parts[0];
        final id = parts[1];
        final path = collection == 'profile'
            ? 'users/$uid'
            : 'users/$uid/$collection/$id';
        await rawWriter.setDocument(path, entry.value);
        rolledBackCount++;
      }
    }

    for (final createdKey in journal.createdItemKeys) {
      final parts = createdKey.split('/');
      if (parts.length >= 2) {
        final collection = parts[0];
        final id = parts[1];
        final path = 'users/$uid/$collection/$id';
        await rawWriter.deleteDocument(path);
        rolledBackCount++;
      }
    }

    journal.phase = JournalPhase.rolledBack;
    await journal.clearFromSecureStorage(storage: secureStorage);

    return OperationResult.completed(
      data: rolledBackCount,
      count: rolledBackCount,
    );
  }
}
