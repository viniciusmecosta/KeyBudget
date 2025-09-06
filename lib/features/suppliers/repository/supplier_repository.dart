import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:key_budget/core/models/supplier_model.dart';

class SupplierRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Supplier> _getSuppliersCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('suppliers')
        .withConverter<Supplier>(
      fromFirestore: (snapshots, _) =>
          Supplier.fromMap(snapshots.data()!, snapshots.id),
      toFirestore: (supplier, _) => supplier.toMap(),
    );
  }

  Future<void> addSupplier(String userId, Supplier supplier) async {
    await _getSuppliersCollection(userId).add(supplier);
  }

  Stream<List<Supplier>> getSuppliersStreamForUser(String userId) {
    final querySnapshot =
    _getSuppliersCollection(userId).orderBy('name').snapshots();
    return querySnapshot
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> updateSupplier(String userId, Supplier supplier) async {
    await _getSuppliersCollection(userId)
        .doc(supplier.id)
        .update(supplier.toMap());
  }

  Future<void> deleteSupplier(String userId, String supplierId) async {
    await _getSuppliersCollection(userId).doc(supplierId).delete();
  }

  Future<List<String>> getUniquePhotoPathsForUser(String userId) async {
    final querySnapshot = await _getSuppliersCollection(userId).get();
    final photoPaths = querySnapshot.docs
        .map((doc) => doc.data().photoPath)
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .toSet()
        .toList();
    return photoPaths;
  }
}