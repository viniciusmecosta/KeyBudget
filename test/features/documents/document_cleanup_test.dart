import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/services/drive_service.dart';
import 'package:key_budget/features/documents/repository/document_repository.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';

class RecordingDocumentRepository extends DocumentRepository {
  final List<String> events;
  final Set<String> pending = {};
  bool failUpdate = false;

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
}

class RecordingDriveService extends DriveService {
  final List<String> events;
  RecordingDriveService(this.events);

  @override
  Future<bool> deleteFile(String fileId, {String? serverClientId}) async {
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
}
