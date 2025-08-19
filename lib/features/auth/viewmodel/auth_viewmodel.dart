import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      );

      await _authRepository.register(newUser);
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

      _setLoading(false);
      return true;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro ao fazer login.');
      _setLoading(false);
      return false;
    }
  }
}
