import 'package:flutter/material.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';

class CredentialViewModel extends ChangeNotifier {
  final CredentialRepository _repository = CredentialRepository();
  final EncryptionService _encryptionService = EncryptionService();
  final CsvService _csvService = CsvService();

  List<Credential> _allCredentials = [];
  bool _isLoading = false;

  List<Credential> get allCredentials => _allCredentials;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchCredentials(int userId) async {
    _setLoading(true);
    _allCredentials = await _repository.getCredentialsForUser(userId);
    _setLoading(false);
  }

  Future<void> addCredential({
    required int userId,
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
      userId: userId,
      location: location,
      login: login,
      encryptedPassword: encryptedPassword,
      email: email,
      phoneNumber: phoneNumber,
      notes: notes,
      logoPath: logoPath,
    );

    await _repository.addCredential(newCredential);
    await fetchCredentials(userId);
  }

  Future<void> updateCredential({
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
      userId: originalCredential.userId,
      location: location,
      login: login,
      encryptedPassword: passwordToSave,
      email: email,
      phoneNumber: phoneNumber,
      notes: notes,
      logoPath: logoPath ?? originalCredential.logoPath,
    );

    await _repository.updateCredential(updatedCredential);
    await fetchCredentials(originalCredential.userId);
  }

  Future<void> deleteCredential(int id, int userId) async {
    await _repository.deleteCredential(id);
    await fetchCredentials(userId);
  }

  Future<bool> exportCredentialsToCsv() async {
    return await _csvService.exportCredentials(_allCredentials);
  }

  Future<int> importCredentialsFromCsv(int userId) async {
    final data = await _csvService.importCsv();
    if (data == null) return 0;

    int count = 0;
    for (var row in data) {
      final plainPassword = row['password']?.toString() ?? '';
      if (plainPassword.isEmpty) continue;

      final newCredential = Credential(
        userId: userId,
        location: row['location']?.toString() ?? 'N/A',
        login: row['login']?.toString() ?? 'N/A',
        encryptedPassword: _encryptionService.encryptData(plainPassword),
        email: row['email']?.toString(),
        phoneNumber: row['phone_number']?.toString(),
        notes: row['notes']?.toString(),
      );
      await _repository.addCredential(newCredential);
      count++;
    }
    await fetchCredentials(userId);
    return count;
  }

  String decryptPassword(String encryptedPassword) {
    return _encryptionService.decryptData(encryptedPassword);
  }
}
