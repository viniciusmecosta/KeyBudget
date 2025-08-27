import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/models/credential_model.dart';

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
}
