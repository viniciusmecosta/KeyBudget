import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  final LocalAuthService _localAuthService = LocalAuthService();

  bool _isLoading = true;
  String? _errorMessage;
  User? _currentUser;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  User? get currentUser => _currentUser;

  AuthViewModel() {
    _authRepository.onAuthStateChanged.listen((user) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
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
      await _authRepository.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        avatarPath: avatarPath,
      );
      await _localAuthService.saveCredentials(email, password);
      return true;
    } on firebase.FirebaseAuthException catch (e) {
      _setErrorMessage(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro desconhecido.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final credential = await _authRepository.signInWithEmail(email, password);
      await _authRepository.ensureCategoriesExist(credential.user!.uid);
      await _localAuthService.saveCredentials(email, password);
      return true;
    } on firebase.FirebaseAuthException catch (e) {
      _setErrorMessage(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro desconhecido.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _setErrorMessage(null);

    try {
      final credential = await _authRepository.signInWithGoogle();
      if (credential != null) {
        final user = credential.user;
        if (user != null && user.email != null) {
          await _authRepository.ensureCategoriesExist(user.uid);
          await _localAuthService.saveCredentials(user.email!, user.uid);
        }
        return true;
      }
      return false;
    } on firebase.FirebaseAuthException catch (e) {
      _setErrorMessage(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro desconhecido.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    final canAuth = await _localAuthService.canAuthenticate();
    if (!canAuth) return false;

    final credentials = await _localAuthService.getCredentials();
    if (credentials == null) return false;

    final isAuthenticated = await _localAuthService.authenticate();
    if (isAuthenticated) {
      return await loginUser(
        email: credentials['email']!,
        password: credentials['password']!,
      );
    }
    return false;
  }

  Future<bool> updateUser({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? newPassword,
  }) async {
    if (_currentUser == null) return false;
    _setLoading(true);

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        avatarPath: avatarPath,
      );
      await _authRepository.updateUserProfile(updatedUser);
      _currentUser = updatedUser;

      if (newPassword != null && newPassword.isNotEmpty) {
        await _authRepository
            .getCurrentFirebaseUser()
            ?.updatePassword(newPassword);
        await _localAuthService.saveCredentials(
            _currentUser!.email, newPassword);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setErrorMessage('Erro ao atualizar perfil.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout(BuildContext context) async {
    context.read<DashboardViewModel>().clearData();
    context.read<ExpenseViewModel>().clearData();
    context.read<CredentialViewModel>().clearData();
    context.read<NavigationViewModel>().clearData();
    context.read<CategoryViewModel>().clearData();

    await _authRepository.signOut();
    await _localAuthService.clearCredentials();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'weak-password':
        return 'A senha fornecida é muito fraca.';
      case 'email-already-in-use':
        return 'Uma conta já existe para este email.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou senha inválidos.';
      default:
        return 'Ocorreu um erro de autenticação.';
    }
  }
}
