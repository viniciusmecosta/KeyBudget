import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class VaultTransaction {
  Future<Map<String, dynamic>?> read(String path);
  void set(String path, Map<String, dynamic> data);
}

abstract interface class VaultStore {
  String newId(String collection);
  Future<Map<String, dynamic>?> read(String path);
  Future<Map<String, Map<String, dynamic>>> list(String collection);
  Future<void> set(String path, Map<String, dynamic> data);
  Future<void> transaction(Future<void> Function(VaultTransaction tx) action);
}

class FirestoreVaultStore implements VaultStore {
  final FirebaseFirestore? _customFirestore;

  FirestoreVaultStore({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  @override
  String newId(String collection) => _firestore.collection(collection).doc().id;

  @override
  Future<Map<String, dynamic>?> read(String path) async =>
      (await _firestore.doc(path).get(const GetOptions(source: Source.server)))
          .data();

  @override
  Future<Map<String, Map<String, dynamic>>> list(String collection) async {
    final snapshot = await _firestore
        .collection(collection)
        .get(const GetOptions(source: Source.server));
    return {for (final doc in snapshot.docs) doc.id: doc.data()};
  }

  @override
  Future<void> set(String path, Map<String, dynamic> data) =>
      _firestore.doc(path).set(data);

  @override
  Future<void> transaction(Future<void> Function(VaultTransaction tx) action) =>
      _firestore.runTransaction(
        (tx) => action(_FirestoreVaultTransaction(_firestore, tx)),
      );
}

class _FirestoreVaultTransaction implements VaultTransaction {
  final FirebaseFirestore firestore;
  final Transaction transaction;

  _FirestoreVaultTransaction(this.firestore, this.transaction);

  @override
  Future<Map<String, dynamic>?> read(String path) async =>
      (await transaction.get(firestore.doc(path))).data();

  @override
  void set(String path, Map<String, dynamic> data) =>
      transaction.set(firestore.doc(path), data);
}
