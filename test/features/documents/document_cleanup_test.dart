import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/features/documents/repository/document_repository.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';

class RecordingDocumentRepository extends DocumentRepository {
  final List<String> events;
  final Set<String> pending = {};
  bool failUpdate = false;
  bool failDelete = false;
  List<Document> family = [];
  List<String> deletedIds = [];

  RecordingDocumentRepository(this.events);

  @override
  Future<void> updateDocumentWithCleanup(
    String userId,
    Document document,
    List<String> driveIds,
  ) async {
    events.add('persist');
    if (failUpdate) throw StateError('write failed');
    pending.addAll(driveIds);
  }

  @override
  Future<List<String>> getPendingAttachmentCleanup(String userId) async =>
      pending.toList();

  @override
  Future<Set<String>> getReferencedAttachmentIds(String userId) async => {};

  @override
  Future<void> acknowledgeAttachmentCleanup(
    String userId,
    String driveId,
  ) async {
    events.add('acknowledge');
    pending.remove(driveId);
  }

  @override
  Future<List<Document>> getDocumentFamily(
    String userId,
    String rootId,
  ) async => family;

  @override
  Future<void> deleteDocumentsWithCleanup(
    String userId,
    List<String> documentIds,
    List<String> driveIds,
  ) async {
    events.add('persist');
    if (failDelete) throw StateError('write failed');
    deletedIds = documentIds;
    pending.addAll(driveIds);
  }
}

class RecordingDriveService extends DriveService {
  final List<String> events;
  RecordingDriveService(this.events);

  @override
  Future<bool> deleteFile(
    String fileId, {
    String? serverClientId,
    bool allowInteractive = true,
  }) async {
    events.add('drive');
    return true;
  }
}

void main() {
  final attachment = Attachment(
    name: 'arquivo.pdf',
    type: 'pdf',
    driveId: 'drive-1',
  );
  final original = Document(
    id: 'doc-1',
    documentName: 'Contrato',
    attachments: [attachment],
  );
  final updated = original.copyWith(attachments: []);

  test('failed document update never deletes its Drive attachment', () async {
    final events = <String>[];
    final repository = RecordingDocumentRepository(events)..failUpdate = true;
    final viewModel = DocumentViewModel(
      repository: repository,
      driveService: RecordingDriveService(events),
      clearLocalCache: (_) async => events.add('cache'),
    );

    expect(await viewModel.updateDocument('u1', updated, original), isFalse);
    expect(events, ['persist']);
    expect(repository.pending, isEmpty);
    viewModel.dispose();
  });

  test(
    'successful document update queues cleanup before deleting the file',
    () async {
      final events = <String>[];
      final repository = RecordingDocumentRepository(events);
      final viewModel = DocumentViewModel(
        repository: repository,
        driveService: RecordingDriveService(events),
        clearLocalCache: (_) async => events.add('cache'),
      );

      expect(await viewModel.updateDocument('u1', updated, original), isTrue);
      expect(events, ['persist', 'drive', 'cache', 'acknowledge']);
      expect(repository.pending, isEmpty);
      viewModel.dispose();
    },
  );

  test(
    'deleting a document removes the complete version family before cleanup',
    () async {
      final events = <String>[];
      final repository = RecordingDocumentRepository(events)
        ..family = [
          original,
          Document(
            id: 'doc-2',
            documentName: 'Contrato',
            originalDocumentId: 'doc-1',
            isPrincipal: false,
            attachments: [
              Attachment(name: 'versao.pdf', type: 'pdf', driveId: 'drive-2'),
            ],
          ),
        ];
      final viewModel = DocumentViewModel(
        repository: repository,
        driveService: RecordingDriveService(events),
        clearLocalCache: (_) async => events.add('cache'),
      );

      expect(await viewModel.deleteDocument('u1', original), isTrue);
      expect(repository.deletedIds, containsAll(['doc-1', 'doc-2']));
      expect(events.first, 'persist');
      expect(events.where((event) => event == 'drive').length, 2);
      expect(repository.pending, isEmpty);
      viewModel.dispose();
    },
  );

  test(
    'deleting one historical version leaves the other versions untouched',
    () async {
      final events = <String>[];
      final oldVersion = Document(
        id: 'doc-2',
        documentName: 'Contrato',
        originalDocumentId: 'doc-1',
        isPrincipal: false,
      );
      final repository = RecordingDocumentRepository(events)
        ..family = [original, oldVersion];
      final viewModel = DocumentViewModel(
        repository: repository,
        driveService: RecordingDriveService(events),
        clearLocalCache: (_) async {},
      );

      expect(await viewModel.deleteVersion('u1', oldVersion), isTrue);
      expect(repository.deletedIds, ['doc-2']);
      viewModel.dispose();
    },
  );

  test('failed family deletion leaves Drive attachments untouched', () async {
    final events = <String>[];
    final repository = RecordingDocumentRepository(events)
      ..family = [original]
      ..failDelete = true;
    final viewModel = DocumentViewModel(
      repository: repository,
      driveService: RecordingDriveService(events),
      clearLocalCache: (_) async {},
    );

    expect(await viewModel.deleteDocument('u1', original), isFalse);
    expect(events, ['persist']);
    viewModel.dispose();
  });
}
