import 'dart:async';

import 'package:flutter/material.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/data_import_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/core/services/pdf_service.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';

class CredentialViewModel extends ChangeNotifier {
  final CredentialRepository _repository = CredentialRepository();
  final EncryptionService _encryptionService = EncryptionService();
  final CsvService _csvService = CsvService();
  final PdfService _pdfService = PdfService();
  final DataImportService _dataImportService = DataImportService();

  List<Credential> _allCredentials = [];
  bool _isLoading = false;
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;
  StreamSubscription? _credentialsSubscription;
  bool _isListening = false;

  List<Credential> get allCredentials => _allCredentials;

  List<String> get userCredentialLogos => _allCredentials
      .map((cred) => cred.logoPath)
      .whereType<String>()
      .where((path) => path.isNotEmpty)
      .toSet()
      .toList();

  bool get isLoading => _isLoading;

  bool get isExportingCsv => _isExportingCsv;

  bool get isExportingPdf => _isExportingPdf;

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setExportingCsv(bool value) {
    if (_isExportingCsv != value) {
      _isExportingCsv = value;
      notifyListeners();
    }
  }

  void _setExportingPdf(bool value) {
    if (_isExportingPdf != value) {
      _isExportingPdf = value;
      notifyListeners();
    }
  }

  void listenToCredentials(String userId) {
    if (_isListening) {
      return;
    }

    _setLoading(true);
    _credentialsSubscription?.cancel();
    _credentialsSubscription =
        _repository.getCredentialsStreamForUser(userId).listen((credentials) {
      _allCredentials = credentials;
      _allCredentials.sort((a, b) =>
          a.location.toLowerCase().compareTo(b.location.toLowerCase()));
      _setLoading(false);
    });
    _isListening = true;
  }

  Future<void> addCredential({
    required String userId,
    required String location,
    required String login,
    required String plainPassword,
    String? email,
    String? phoneNumber,
    String? notes,
    String? logoPath,
  }) async {
    final encryptedPassword = _encryptionService.encryptData(plainPassword);
    final newCredential = Credential(
      location: location,
      login: login,
      encryptedPassword: encryptedPassword,
      email: email,
      phoneNumber: phoneNumber,
      notes: notes,
      logoPath: logoPath,
    );
    await _repository.addCredential(userId, newCredential);
  }

  Future<void> updateCredential({
    required String userId,
    required Credential originalCredential,
    required String location,
    required String login,
    String? newPlainPassword,
    String? email,
    String? phoneNumber,
    String? notes,
    String? logoPath,
  }) async {
    String passwordToSave = originalCredential.encryptedPassword;
    if (newPlainPassword != null && newPlainPassword.isNotEmpty) {
      final decryptedOriginal =
          decryptPassword(originalCredential.encryptedPassword);
      if (newPlainPassword != decryptedOriginal) {
        passwordToSave = _encryptionService.encryptData(newPlainPassword);
      }
    }
    final updatedCredential = Credential(
      id: originalCredential.id,
      location: location,
      login: login,
      encryptedPassword: passwordToSave,
      email: email,
      phoneNumber: phoneNumber,
      notes: notes,
      logoPath: logoPath,
    );
    await _repository.updateCredential(userId, updatedCredential);
  }

  Future<void> deleteCredential(String userId, String credentialId) async {
    await _repository.deleteCredential(userId, credentialId);
  }

  Future<bool> exportCredentialsToCsv(BuildContext context) async {
    _setExportingCsv(true);
    try {
      return await _csvService.exportCredentials(context, _allCredentials);
    } finally {
      _setExportingCsv(false);
    }
  }

  Future<void> exportCredentialsToPdf(BuildContext context) async {
    _setExportingPdf(true);
    try {
      await _pdfService.exportCredentialsPdf(context, this);
    } finally {
      _setExportingPdf(false);
    }
  }

  Future<int> importCredentialsFromCsv(String userId) async {
    final data = await _csvService.importCsv();
    if (data == null) return 0;
    int count = 0;
    for (var row in data) {
      final plainPassword = row['password']?.toString() ?? '';
      if (plainPassword.isEmpty) continue;
      final newCredential = Credential(
        location: row['location']?.toString() ?? 'N/A',
        login: row['login']?.toString() ?? 'N/A',
        encryptedPassword: _encryptionService.encryptData(plainPassword),
        email: row['email']?.toString(),
        phoneNumber: row['phone_number']?.toString(),
        notes: row['notes']?.toString(),
      );
      await _repository.addCredential(userId, newCredential);
      count++;
    }
    return count;
  }

  Future<int> importCredentialsFromJson(String userId) async {
    _setLoading(true);
    final count = await _dataImportService.importCredentialsFromJson(userId);
    _setLoading(false);
    return count;
  }

  String decryptPassword(String encryptedPassword) {
    return _encryptionService.decryptData(encryptedPassword);
  }

  void clearData() {
    _credentialsSubscription?.cancel();
    _allCredentials = [];
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _credentialsSubscription?.cancel();
    super.dispose();
  }
}
