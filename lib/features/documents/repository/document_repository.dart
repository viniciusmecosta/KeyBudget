import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/models/document_model.dart';

class DocumentRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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

  Future<void> addDocument(String userId, Document document) async {
    await getDocumentsCollection(userId).add(document);
  }

  Stream<List<Document>> getDocumentsStream(String userId) {
    return getDocumentsCollection(userId)
        .orderBy('dataExpedicao', descending: true)
        .snapshots()
        .map(
            (snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Document>> getDocumentsForUser(String userId) async {
    final querySnapshot = await getDocumentsCollection(userId)
        .orderBy('dataExpedicao', descending: true)
        .get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateDocument(String userId, Document document) async {
    await getDocumentsCollection(userId)
        .doc(document.id)
        .update(document.toMap());
  }

  Future<void> deleteDocument(String userId, String documentId) async {
    await getDocumentsCollection(userId).doc(documentId).delete();
  }
}