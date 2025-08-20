import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final LocalAuthService _localAuthService = LocalAuthService();
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatarPath,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final existingUser = await _authRepository.getUserByEmail(email);
      if (existingUser != null) {
        _setErrorMessage('Este email já está em uso.');
        _setLoading(false);
        return false;
      }

      final passwordHash = _hashPassword(password);
      final newUser = User(
        name: name,
        email: email,
        passwordHash: passwordHash,
        phoneNumber: phoneNumber,
        avatarPath: avatarPath,
      );

      _currentUser = await _authRepository.register(newUser);
      await _localAuthService.saveLastUser(_currentUser!.id.toString());
      _setLoading(false);
      return true;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro ao registrar.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final user = await _authRepository.getUserByEmail(email);
      if (user == null) {
        _setErrorMessage('Email ou senha inválidos.');
        _setLoading(false);
        return false;
      }

      final passwordHash = _hashPassword(password);
      if (user.passwordHash != passwordHash) {
        _setErrorMessage('Email ou senha inválidos.');
        _setLoading(false);
        return false;
      }

      _currentUser = user;
      await _localAuthService.saveLastUser(user.id.toString());
      _setLoading(false);
      return true;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro ao fazer login.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateUser({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? newPassword,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      String passwordHash = _currentUser!.passwordHash;
      if (newPassword != null && newPassword.isNotEmpty) {
        passwordHash = _hashPassword(newPassword);
      }

      final updatedUser = _currentUser!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        avatarPath: avatarPath,
        passwordHash: passwordHash,
      );

      await _authRepository.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro ao atualizar o perfil.');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    _setLoading(true);
    final lastUserId = await _localAuthService.getLastUser();
    if (lastUserId == null) {
      _setLoading(false);
      return false;
    }

    final isAuthenticated = await _localAuthService.authenticate();
    if (isAuthenticated) {
      _currentUser = await _authRepository.getUserById(int.parse(lastUserId));
      _setLoading(false);
      return _currentUser != null;
    }

    _setLoading(false);
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _localAuthService.clearLastUser();
    notifyListeners();
  }
}
