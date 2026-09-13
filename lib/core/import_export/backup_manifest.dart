import 'dart:convert';

class BackupAttachmentMeta {
  final String internalId;
  final String? originalDriveId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String sha256;

  const BackupAttachmentMeta({
    required this.internalId,
    this.originalDriveId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.sha256,
  });

  Map<String, dynamic> toMap() => {
        'internalId': internalId,
        if (originalDriveId != null) 'originalDriveId': originalDriveId,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'sha256': sha256,
      };

  factory BackupAttachmentMeta.fromMap(Map<String, dynamic> map) {
    return BackupAttachmentMeta(
      internalId: map['internalId'] as String,
      originalDriveId: map['originalDriveId'] as String?,
      fileName: map['fileName'] as String,
      mimeType: map['mimeType'] as String,
      sizeBytes: map['sizeBytes'] as int,
      sha256: map['sha256'] as String,
    );
  }
}

class BackupCompleteness {
  final bool isComplete;
  final List<String> missingAttachments;
  final List<String> undecryptableCredentials;
  final List<String> warnings;

  const BackupCompleteness({
    required this.isComplete,
    this.missingAttachments = const [],
    this.undecryptableCredentials = const [],
    this.warnings = const [],
  });

  Map<String, dynamic> toMap() => {
        'isComplete': isComplete,
        'missingAttachments': missingAttachments,
        'undecryptableCredentials': undecryptableCredentials,
        'warnings': warnings,
      };

  factory BackupCompleteness.fromMap(Map<String, dynamic> map) {
    return BackupCompleteness(
      isComplete: map['isComplete'] as bool? ?? true,
      missingAttachments:
          (map['missingAttachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      undecryptableCredentials:
          (map['undecryptableCredentials'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      warnings:
          (map['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class BackupManifest {
  final int formatVersion;
  final String appVersion;
  final DateTime createdAt;
  final String backupId;
  final String originUid;
  final List<String> modules;
  final Map<String, int> counts;
  final Map<String, String> hashes;
  final List<BackupAttachmentMeta> attachments;
  final BackupCompleteness completeness;

  const BackupManifest({
    this.formatVersion = 1,
    required this.appVersion,
    required this.createdAt,
    required this.backupId,
    required this.originUid,
    required this.modules,
    required this.counts,
    required this.hashes,
    this.attachments = const [],
    required this.completeness,
  });

  Map<String, dynamic> toMap() => {
        'formatVersion': formatVersion,
        'appVersion': appVersion,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'backupId': backupId,
        'originUid': originUid,
        'modules': modules,
        'counts': counts,
        'hashes': hashes,
        'attachments': attachments.map((a) => a.toMap()).toList(),
        'completeness': completeness.toMap(),
      };

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toMap());
  }

  factory BackupManifest.fromMap(Map<String, dynamic> map) {
    return BackupManifest(
      formatVersion: map['formatVersion'] as int? ?? 1,
      appVersion: map['appVersion'] as String? ?? '1.0.0',
      createdAt: DateTime.parse(map['createdAt'] as String),
      backupId: map['backupId'] as String,
      originUid: map['originUid'] as String,
      modules:
          (map['modules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      counts:
          (map['counts'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          const {},
      hashes:
          (map['hashes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      attachments:
          (map['attachments'] as List<dynamic>?)
              ?.map(
                (e) => BackupAttachmentMeta.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      completeness: map['completeness'] != null
          ? BackupCompleteness.fromMap(
              map['completeness'] as Map<String, dynamic>,
            )
          : const BackupCompleteness(isComplete: true),
    );
  }

  factory BackupManifest.fromJsonString(String jsonStr) {
    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return BackupManifest.fromMap(map);
  }
}
