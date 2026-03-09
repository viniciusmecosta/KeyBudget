import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/folder_model.dart';

class CredentialRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Credential> _getCredentialsCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('credentials')
        .withConverter<Credential>(
          fromFirestore: (snapshots, _) =>
              Credential.fromMap(snapshots.data()!, snapshots.id),
          toFirestore: (credential, _) => credential.toMap(),
        );
  }

  CollectionReference<Folder> _getFoldersCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('folders')
        .withConverter<Folder>(
          fromFirestore: (snapshots, _) =>
              Folder.fromMap(snapshots.data()!, snapshots.id),
          toFirestore: (folder, _) => folder.toMap(),
        );
  }

  Future<void> addCredential(String userId, Credential credential) async {
    await _getCredentialsCollection(userId).add(credential);
  }

  Stream<List<Credential>> getCredentialsStreamForUser(String userId) {
    final querySnapshot =
        _getCredentialsCollection(userId).orderBy('location').snapshots();
    return querySnapshot
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Credential>> getCredentialsForUser(String userId) async {
    final querySnapshot =
        await _getCredentialsCollection(userId).orderBy('location').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateCredential(String userId, Credential credential) async {
    await _getCredentialsCollection(userId)
        .doc(credential.id)
        .update(credential.toMap());
  }

  Future<void> deleteCredential(String userId, String credentialId) async {
    await _getCredentialsCollection(userId).doc(credentialId).delete();
  }

  Future<List<String>> getUniqueLogoPathsForUser(String userId) async {
    final querySnapshot = await _getCredentialsCollection(userId).get();
    final logoPaths = querySnapshot.docs
        .map((doc) => doc.data().logoPath)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toSet()
        .toList();
    return logoPaths;
  }

  Stream<List<Folder>> getFoldersStreamForUser(String userId) {
    final querySnapshot =
        _getFoldersCollection(userId).orderBy('name').snapshots();
    return querySnapshot
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addFolder(String userId, Folder folder) async {
    await _getFoldersCollection(userId).add(folder);
  }

  Future<void> deleteFolder(String userId, String folderId) async {
    await _getFoldersCollection(userId).doc(folderId).delete();

    final batch = _firestore.batch();
    final credentials = await _getCredentialsCollection(userId)
        .where('folder_id', isEqualTo: folderId)
        .get();

    for (var doc in credentials.docs) {
      batch.update(doc.reference, {'folder_id': null});
    }
    await batch.commit();
  }
}
