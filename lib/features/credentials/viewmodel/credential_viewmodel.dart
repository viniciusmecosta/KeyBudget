import 'package:flutter/material.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/services/encryption_service.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';

class CredentialViewModel extends ChangeNotifier {
  final CredentialRepository _repository = CredentialRepository();
  final EncryptionService _encryptionService = EncryptionService();

  List<Credential> _credentials = [];
  bool _isLoading = false;

  List<Credential> get credentials => _credentials;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchCredentials(int userId) async {
    _setLoading(true);
    _credentials = await _repository.getCredentialsForUser(userId);
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
    );

    await _repository.addCredential(newCredential);
    await fetchCredentials(userId);
  }

  Future<void> deleteCredential(int id, int userId) async {
    await _repository.deleteCredential(id);
    await fetchCredentials(userId);
  }

  String decryptPassword(String encryptedPassword) {
    return _encryptionService.decryptData(encryptedPassword);
  }
}
