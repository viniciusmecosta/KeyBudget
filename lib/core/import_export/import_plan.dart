import 'backup_manifest.dart';

enum ImportAction {

  create,

  skip,

  conflict,
}

enum ConflictResolution {

  keepTarget,

  replaceWithSource,
}

class ImportItemPlan {
  final String collection;
  final String documentId;
  final ImportAction action;
  final Map<String, dynamic> sourceData;
  final Map<String, dynamic>? targetData;
  final String sourceDigest;
  final String? targetDigest;
  final String? parentCollection;
  final String? parentId;
  final String? portablePassword;
  final bool hasParentConflict;
  ConflictResolution resolution;

  ImportItemPlan({
    required this.collection,
    required this.documentId,
    required this.action,
    required this.sourceData,
    this.targetData,
    required this.sourceDigest,
    this.targetDigest,
    this.parentCollection,
    this.parentId,
    this.portablePassword,
    this.hasParentConflict = false,
    this.resolution = ConflictResolution.keepTarget,
  });

  bool get willWrite {
    if (action == ImportAction.create) return true;
    if (action == ImportAction.conflict &&
        resolution == ConflictResolution.replaceWithSource) {
      return true;
    }
    return false;
  }
}

class ImportAttachmentPlan {
  final String internalId;
  final String? originalDriveId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String sha256;
  final bool existsInTarget;

  const ImportAttachmentPlan({
    required this.internalId,
    this.originalDriveId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
    this.existsInTarget = false,
  });

  bool get willUpload => !existsInTarget;
}

class ImportPlan {
  final String backupId;
  final String originUid;
  final String targetUid;
  final BackupManifest manifest;
  final List<ImportItemPlan> items;
  final List<ImportAttachmentPlan> attachments;
  final List<String> validationErrors;
  final List<String> warnings;
  final List<String> orphans;

  ImportPlan({
    required this.backupId,
    required this.originUid,
    required this.targetUid,
    required this.manifest,
    required this.items,
    required this.attachments,
    this.validationErrors = const [],
    this.warnings = const [],
    this.orphans = const [],
  });

  bool get isUidMatched => originUid == targetUid;

  bool get canExecute => isUidMatched && validationErrors.isEmpty;

  int get createCount =>
      items.where((i) => i.action == ImportAction.create).length;

  int get skipCount =>
      items.where((i) => i.action == ImportAction.skip).length;

  int get conflictCount =>
      items.where((i) => i.action == ImportAction.conflict).length;

  int get willWriteCount => items.where((i) => i.willWrite).length;

  int get attachmentsToUploadCount =>
      attachments.where((a) => a.willUpload).length;

  int get totalSizeBytesToUpload => attachments
      .where((a) => a.willUpload)
      .fold<int>(0, (sum, a) => sum + a.sizeBytes);

  void setResolution(
    String collection,
    String documentId,
    ConflictResolution resolution,
  ) {
    for (final item in items) {
      if (item.collection == collection && item.documentId == documentId) {
        item.resolution = resolution;
        break;
      }
    }
  }

  void setBulkConflictResolution(
    ConflictResolution resolution, {
    String? collection,
  }) {
    for (final item in items) {
      if (item.action == ImportAction.conflict) {
        if (collection == null || item.collection == collection) {
          item.resolution = resolution;
        }
      }
    }
  }
}
