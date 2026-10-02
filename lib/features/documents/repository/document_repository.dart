import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/models/document_model.dart';

class DocumentRepository {
  final FirebaseFirestore? _customFirestore;

  DocumentRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userRef(String userId) =>
      firestore.collection('users').doc(userId);

  CollectionReference<Document> getDocumentsCollection(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('documents')
        .withConverter<Document>(
          fromFirestore: (snapshots, _) =>
              Document.fromMap(snapshots.data()!, snapshots.id),
          toFirestore: (document, _) => document.toMap(),
        );
  }

  Future<String> addDocument(String userId, Document document) async {
    final docRef = await getDocumentsCollection(userId).add(document);
    return docRef.id;
  }

  Stream<List<Document>> getDocumentsStream(String userId) {
    return getDocumentsCollection(userId)
        .orderBy('documentName')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Document>> getDocumentsForUser(String userId) async {
    final querySnapshot = await getDocumentsCollection(
      userId,
    ).orderBy('documentName').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateDocument(String userId, Document document) async {
    await getDocumentsCollection(
      userId,
    ).doc(document.id).update(document.toMap());
  }

  Future<void> updateDocumentWithCleanup(
    String userId,
    Document document,
    List<String> driveIds,
  ) async {
    final batch = firestore.batch();
    batch.update(
      getDocumentsCollection(userId).doc(document.id),
      document.toMap(),
    );
    if (driveIds.isNotEmpty) {
      batch.update(_userRef(userId), {
        'pendingDocumentAttachmentCleanup': FieldValue.arrayUnion(driveIds),
      });
    }
    await batch.commit();
  }

  Future<List<String>> getPendingAttachmentCleanup(String userId) async {
    final snapshot = await _userRef(userId).get();
    final value = snapshot.data()?['pendingDocumentAttachmentCleanup'];
    return value is List ? value.whereType<String>().toList() : [];
  }

  Future<Set<String>> getReferencedAttachmentIds(String userId) async {
    final snapshot = await getDocumentsCollection(
      userId,
    ).get(const GetOptions(source: Source.server));
    return {
      for (final doc in snapshot.docs)
        for (final attachment in doc.data().attachments) attachment.driveId,
    };
  }

  Future<void> acknowledgeAttachmentCleanup(
    String userId,
    String driveId,
  ) async {
    await _userRef(userId).update({
      'pendingDocumentAttachmentCleanup': FieldValue.arrayRemove([driveId]),
    });
  }

  Future<void> deleteDocument(String userId, String documentId) async {
    await getDocumentsCollection(userId).doc(documentId).delete();
  }

  Future<List<Document>> getDocumentFamily(String userId, String rootId) async {
    final collection = getDocumentsCollection(userId);
    final root = await collection
        .doc(rootId)
        .get(const GetOptions(source: Source.server));
    final versions = await collection
        .where('originalDocumentId', isEqualTo: rootId)
        .get(const GetOptions(source: Source.server));
    final byId = <String, Document>{
      if (root.exists) root.id: root.data()!,
      for (final snapshot in versions.docs) snapshot.id: snapshot.data(),
    };
    return byId.values.toList();
  }

  Future<void> deleteDocumentsWithCleanup(
    String userId,
    List<String> documentIds,
    List<String> driveIds,
  ) async {
    if (documentIds.length + (driveIds.isNotEmpty ? 1 : 0) > 500) {
      throw StateError('O histórico excede o limite de uma operação.');
    }
    final batch = firestore.batch();
    final collection = getDocumentsCollection(userId);
    for (final id in documentIds) {
      batch.delete(collection.doc(id));
    }
    if (driveIds.isNotEmpty) {
      batch.update(_userRef(userId), {
        'pendingDocumentAttachmentCleanup': FieldValue.arrayUnion(driveIds),
      });
    }
    await batch.commit();
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepository(),
);
