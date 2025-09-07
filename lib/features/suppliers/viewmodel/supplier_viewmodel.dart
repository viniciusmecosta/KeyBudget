import 'dart:async';

import 'package:flutter/material.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/features/suppliers/repository/supplier_repository.dart';

class SupplierViewModel extends ChangeNotifier {
  final SupplierRepository _repository = SupplierRepository();

  List<Supplier> _allSuppliers = [];
  bool _isLoading = false;
  StreamSubscription? _suppliersSubscription;
  bool _isListening = false;

  List<Supplier> get allSuppliers => _allSuppliers;

  bool get isLoading => _isLoading;

  List<String> get userSupplierPhotos => _allSuppliers
      .map((supp) => supp.photoPath)
      .whereType<String>()
      .where((path) => path.isNotEmpty)
      .toSet()
      .toList();

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void listenToSuppliers(String userId) {
    if (_isListening) {
      return;
    }

    _setLoading(true);
    _suppliersSubscription?.cancel();
    _suppliersSubscription =
        _repository.getSuppliersStreamForUser(userId).listen((suppliers) {
      _allSuppliers = suppliers;
      _allSuppliers
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _setLoading(false);
    });
    _isListening = true;
  }

  Future<void> addSupplier({
    required String userId,
    required String name,
    String? representativeName,
    String? email,
    String? phoneNumber,
    String? photoPath,
    String? notes,
  }) async {
    final newSupplier = Supplier(
      name: name,
      representativeName: representativeName,
      email: email,
      phoneNumber: phoneNumber,
      photoPath: photoPath,
      notes: notes,
    );
    await _repository.addSupplier(userId, newSupplier);
  }

  Future<void> updateSupplier({
    required String userId,
    required Supplier originalSupplier,
    required String name,
    String? representativeName,
    String? email,
    String? phoneNumber,
    String? photoPath,
    String? notes,
  }) async {
    final updatedSupplier = Supplier(
      id: originalSupplier.id,
      name: name,
      representativeName: representativeName,
      email: email,
      phoneNumber: phoneNumber,
      photoPath: photoPath,
      notes: notes,
    );
    await _repository.updateSupplier(userId, updatedSupplier);
  }

  Future<void> deleteSupplier(String userId, String supplierId) async {
    await _repository.deleteSupplier(userId, supplierId);
  }

  void clearData() {
    _suppliersSubscription?.cancel();
    _allSuppliers = [];
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _suppliersSubscription?.cancel();
    super.dispose();
  }
}
