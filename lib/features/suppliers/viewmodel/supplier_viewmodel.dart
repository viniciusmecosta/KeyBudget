import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/features/suppliers/repository/supplier_repository.dart';

class SupplierViewModel extends ChangeNotifier {
  final SupplierRepository _repository;

  SupplierViewModel({SupplierRepository? repository})
    : _repository = repository ?? SupplierRepository();

  List<Supplier> _allSuppliers = [];
  bool _isLoading = false;
  StreamSubscription? _suppliersSubscription;
  bool _isListening = false;
  bool _hasLoadError = false;
  bool _isOffline = false;

  List<Supplier> get allSuppliers => _allSuppliers;

  String _searchQuery = '';

  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<Supplier> get filteredSuppliers {
    if (_searchQuery.isEmpty) return _allSuppliers;
    return _allSuppliers.where((s) {
      final name = s.name.toLowerCase();
      final rep = s.representativeName?.toLowerCase() ?? '';
      final phone = s.phoneNumber ?? '';
      final email = s.email?.toLowerCase() ?? '';
      return name.contains(_searchQuery) ||
          rep.contains(_searchQuery) ||
          phone.contains(_searchQuery) ||
          email.contains(_searchQuery);
    }).toList();
  }

  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;
  bool get isOffline => _isOffline;

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
    _hasLoadError = false;
    _isOffline = false;
    _suppliersSubscription?.cancel();
    _suppliersSubscription = _repository
        .getSuppliersStreamForUser(userId)
        .listen(
          (suppliers) {
            _allSuppliers = suppliers;
            _hasLoadError = false;
            _isOffline = false;
            _allSuppliers.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
            _setLoading(false);
          },
          onError: (Object error) {
            _hasLoadError = true;
            _isOffline =
                error is FirebaseException &&
                (error.code == 'unavailable' ||
                    error.code == 'network-request-failed');
            _isListening = false;
            _setLoading(false);
          },
        );
    _isListening = true;
  }

  void retryListenToSuppliers(String userId) {
    _isListening = false;
    listenToSuppliers(userId);
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

  Future<void> restoreSupplier(String userId, Supplier supplier) async {
    await _repository.restoreSupplier(userId, supplier);
  }

  void clearData() {
    _suppliersSubscription?.cancel();
    _allSuppliers = [];
    _isListening = false;
    _hasLoadError = false;
    _isOffline = false;
    notifyListeners();
  }

  @visibleForTesting
  void setSuppliersForTesting(List<Supplier> suppliers) {
    _allSuppliers = suppliers;
    notifyListeners();
  }

  @override
  void dispose() {
    _suppliersSubscription?.cancel();
    super.dispose();
  }
}

final supplierViewModelProvider = ChangeNotifierProvider<SupplierViewModel>(
  (ref) => SupplierViewModel(repository: ref.read(supplierRepositoryProvider)),
);
