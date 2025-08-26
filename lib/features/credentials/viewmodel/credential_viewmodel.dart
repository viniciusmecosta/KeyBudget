import 'package:flutter/material.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/data_import_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';

class CredentialViewModel extends ChangeNotifier {
  final CredentialRepository _repository = CredentialRepository();
  final EncryptionService _encryptionService = EncryptionService();
  final CsvService _csvService = CsvService();
  final DataImportService _dataImportService = DataImportService();

  List<Credential> _allCredentials = [];
  bool _isLoading = false;

  List<Credential> get allCredentials => _allCredentials;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchCredentials(String userId) async {
    _setLoading(true);
    _allCredentials = await _repository.getCredentialsForUser(userId);
    _setLoading(false);
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
    await fetchCredentials(userId);
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
      passwordToSave = _encryptionService.encryptData(newPlainPassword);
    }

    final updatedCredential = Credential(
      id: originalCredential.id,
      location: location,
      login: login,
      encryptedPassword: passwordToSave,
      email: email,
      phoneNumber: phoneNumber,
      notes: notes,
      logoPath: logoPath ?? originalCredential.logoPath,
    );

    await _repository.updateCredential(userId, updatedCredential);
    await fetchCredentials(userId);
  }

  Future<void> deleteCredential(String userId, String credentialId) async {
    await _repository.deleteCredential(userId, credentialId);
    await fetchCredentials(userId);
  }

  Future<bool> exportCredentialsToCsv() async {
    return await _csvService.exportCredentials(_allCredentials);
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
    await fetchCredentials(userId);
    return count;
  }

  Future<int> importCredentialsFromJson(String userId) async {
    _setLoading(true);
    final count = await _dataImportService.importCredentialsFromJson(userId);
    await fetchCredentials(userId);
    _setLoading(false);
    return count;
  }

  String decryptPassword(String encryptedPassword) {
    return _encryptionService.decryptData(encryptedPassword);
  }

  void clearData() {
    _allCredentials = [];
    notifyListeners();
  }
}
