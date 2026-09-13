import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum JournalPhase {
  idle,
  categoriesAndFolders,
  recurringRulesSuspended,
  expensesCredentialsSuppliers,
  attachmentUploads,
  documentsAndVersions,
  profilePreferences,
  validationAndResume,
  completed,
  rolledBack,
}

class OperationJournal {
  final String operationId;
  final String uid;
  final String kind;
  final int formatVersion;
  JournalPhase phase;
  final Set<String> committedItemKeys;
  final Set<String> createdItemKeys;
  final Map<String, Map<String, dynamic>> beforeImages;
  final Map<String, String> uploadedAttachmentIds;
  final List<String> logMessages;

  OperationJournal({
    required this.operationId,
    required this.uid,
    this.kind = 'restore',
    this.formatVersion = 1,
    this.phase = JournalPhase.idle,
    Set<String>? committedItemKeys,
    Set<String>? createdItemKeys,
    Map<String, Map<String, dynamic>>? beforeImages,
    Map<String, String>? uploadedAttachmentIds,
    List<String>? logMessages,
  })  : committedItemKeys = committedItemKeys ?? {},
        createdItemKeys = createdItemKeys ?? {},
        beforeImages = beforeImages ?? {},
        uploadedAttachmentIds = uploadedAttachmentIds ?? {},
        logMessages = logMessages ?? [];

  static String makeKey(String collection, String id) => '$collection/$id';

  bool isItemCommitted(String collection, String id) {
    return committedItemKeys.contains(makeKey(collection, id));
  }

  void recordCommit(
    String collection,
    String id, {
    bool isCreate = true,
    Map<String, dynamic>? beforeImage,
  }) {
    final key = makeKey(collection, id);
    committedItemKeys.add(key);
    if (isCreate) {
      createdItemKeys.add(key);
    } else if (beforeImage != null) {
      beforeImages[key] = beforeImage;
    }
  }

  void recordUpload(String internalId, String newDriveId) {
    uploadedAttachmentIds[internalId] = newDriveId;
  }

  void log(String message) {
    logMessages.add('${DateTime.now().toUtc().toIso8601String()}: $message');
  }

  Map<String, dynamic> toMap() => {
        'operationId': operationId,
        'uid': uid,
        'kind': kind,
        'formatVersion': formatVersion,
        'phase': phase.name,
        'committedItemKeys': committedItemKeys.toList(),
        'createdItemKeys': createdItemKeys.toList(),
        'beforeImages': beforeImages,
        'uploadedAttachmentIds': uploadedAttachmentIds,
        'logMessages': logMessages,
      };

  factory OperationJournal.fromMap(Map<String, dynamic> map) {
    return OperationJournal(
      operationId: map['operationId'] as String,
      uid: map['uid'] as String,
      kind: map['kind'] as String? ?? 'restore',
      formatVersion: map['formatVersion'] as int? ?? 1,
      phase: JournalPhase.values.firstWhere(
        (p) => p.name == map['phase'],
        orElse: () => JournalPhase.idle,
      ),
      committedItemKeys: (map['committedItemKeys'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      createdItemKeys: (map['createdItemKeys'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      beforeImages: (map['beforeImages'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
          ) ??
          {},
      uploadedAttachmentIds:
          (map['uploadedAttachmentIds'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      logMessages: (map['logMessages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Future<void> saveToSecureStorage({FlutterSecureStorage? storage}) async {
    final secStorage = storage ?? const FlutterSecureStorage();
    final jsonStr = json.encode(toMap());
    await secStorage.write(
      key: 'kbudget_journal_${uid}_$operationId',
      value: jsonStr,
    );
  }

  static Future<OperationJournal?> loadFromSecureStorage({
    required String uid,
    String? operationId,
    FlutterSecureStorage? storage,
  }) async {
    final secStorage = storage ?? const FlutterSecureStorage();
    if (operationId != null) {
      final jsonStr = await secStorage.read(
        key: 'kbudget_journal_${uid}_$operationId',
      );
      if (jsonStr != null) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        return OperationJournal.fromMap(map);
      }
      return null;
    }

    final all = await secStorage.readAll();
    final prefix = 'kbudget_journal_${uid}_';
    for (final entry in all.entries) {
      if (entry.key.startsWith(prefix)) {
        try {
          final map = json.decode(entry.value) as Map<String, dynamic>;
          final journal = OperationJournal.fromMap(map);
          if (journal.phase != JournalPhase.completed &&
              journal.phase != JournalPhase.rolledBack) {
            return journal;
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> clearFromSecureStorage({FlutterSecureStorage? storage}) async {
    final secStorage = storage ?? const FlutterSecureStorage();
    await secStorage.delete(key: 'kbudget_journal_${uid}_$operationId');
  }
}
