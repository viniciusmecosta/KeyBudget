import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'package:key_budget/core/services/app_security_service.dart';
import 'package:key_budget/core/services/home_widget_service.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/core/services/notification_service.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

enum AuthOperation {
  none,
  emailLogin,
  googleLogin,
  register,
  resetPassword,
  updateProfile,
  localUnlock,
  logout,
}

class UpdateUserResult {
  final bool profileUpdated;
  final bool? passwordUpdated;
  final bool requiresRecentLogin;
  final String? errorMessage;

  const UpdateUserResult({
    required this.profileUpdated,
    this.passwordUpdated,
    this.requiresRecentLogin = false,
    this.errorMessage,
  });

  bool get isSuccess =>
      profileUpdated && (passwordUpdated == null || passwordUpdated == true);
}

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final LocalAuthService _localAuthService;

  AuthOperation _currentOperation = AuthOperation.none;
  bool _isInitialized = false;
  String? _errorMessage;
  User? _currentUser;
  bool _justAuthenticated = false;

  AuthOperation get currentOperation => _currentOperation;
  bool get isLoading => _currentOperation != AuthOperation.none;
  bool isOperating(AuthOperation op) => _currentOperation == op;

  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get justAuthenticated => _justAuthenticated;

  StreamSubscription? _userProfileSub;
  StreamSubscription? _authStateSub;

  AuthViewModel({
    AuthRepository? authRepository,
    LocalAuthService? localAuthService,
    bool listenToAuthChanges = true,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _localAuthService = localAuthService ?? LocalAuthService() {
    if (listenToAuthChanges) {
      _authStateSub =
          _authRepository.firebaseAuthStateChanges.listen((firebaseUser) {
        _userProfileSub?.cancel();

        if (firebaseUser == null) {
          _currentUser = null;
          if (!_isInitialized) {
            _isInitialized = true;
          }
          notifyListeners();
        } else {
          _userProfileSub = _authRepository
              .getUserProfileStream(firebaseUser.uid)
              .listen((user) {
            _currentUser = user;
            if (user != null) {
              AppSecurityService.setSecure(user.appLocked ?? true);
            }
            if (!_isInitialized) {
              _isInitialized = true;
            }
            notifyListeners();
          }, onError: (e) {
            if (kDebugMode) {
              print("Error listening to user profile: $e");
            }
            _setErrorMessage('Erro ao carregar dados do perfil.');
            if (!_isInitialized) {
              _isInitialized = true;
            }
            notifyListeners();
          });
        }
      });
    }
  }

  void consumeJustAuthenticated() {
    _justAuthenticated = false;
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
    if (_currentOperation != AuthOperation.none) return false;
    _currentOperation = AuthOperation.register;
    _setErrorMessage(null);
    notifyListeners();

    try {
      await _authRepository.signUpWithEmail(
        name: name,
        email: email.trim(),
        password: password,
        phoneNumber: phoneNumber,
        avatarPath: avatarPath,
      );
      _justAuthenticated = true;
      return true;
    } on firebase.FirebaseAuthException catch (e) {
      _setErrorMessage(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro desconhecido.');
      return false;
    } finally {
      _currentOperation = AuthOperation.none;
      notifyListeners();
    }
  }

  Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    if (_currentOperation != AuthOperation.none) return false;
    _currentOperation = AuthOperation.emailLogin;
    _setErrorMessage(null);
    notifyListeners();

    try {
      final credential = await _authRepository.signInWithEmail(
        email.trim(),
        password,
      );
      await _authRepository.ensureCategoriesExist(credential.user!.uid);
      _justAuthenticated = true;
      return true;
    } on firebase.FirebaseAuthException catch (e) {
      _setErrorMessage(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro desconhecido.');
      return false;
    } finally {
      _currentOperation = AuthOperation.none;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    if (_currentOperation != AuthOperation.none) return false;
    _currentOperation = AuthOperation.googleLogin;
    _setErrorMessage(null);
    notifyListeners();

    try {
      final userProfile = await _authRepository.signInWithGoogle();
      if (userProfile != null) {
        _currentUser = userProfile;
        _justAuthenticated = true;
        return true;
      } else {
        return false;
      }
    } on firebase.FirebaseAuthException catch (e) {
      _setErrorMessage(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setErrorMessage('Ocorreu um erro desconhecido.');
      return false;
    } finally {
      _currentOperation = AuthOperation.none;
      notifyListeners();
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (_currentUser == null) return false;
    if (_currentOperation != AuthOperation.none) return false;

    final canAuth = await _localAuthService.canAuthenticate();
    if (!canAuth) return false;

    _currentOperation = AuthOperation.localUnlock;
    notifyListeners();

    try {
      final isAuthenticated = await _localAuthService.authenticate();
      if (isAuthenticated) {
        _justAuthenticated = true;
        return true;
      }
      return false;
    } finally {
      _currentOperation = AuthOperation.none;
      notifyListeners();
    }
  }

  Future<OperationResult<void>> sendPasswordResetEmail(String email) async {
    if (_currentOperation != AuthOperation.none) {
      return OperationResult.conflict(
        message: 'Uma operação já está em andamento.',
      );
    }
    _currentOperation = AuthOperation.resetPassword;
    _setErrorMessage(null);
    notifyListeners();

    try {
      final normalized = email.trim();
      if (normalized.isEmpty || !normalized.contains('@')) {
        return OperationResult.failed(
          rawErrorCode: 'invalid-email',
          safeError: 'Informe um e-mail válido.',
        );
      }
      await _authRepository.sendPasswordResetEmail(normalized);
      return OperationResult.completed(
        message:
            'Se houver uma conta com este e-mail, você receberá as instruções para redefinir sua senha.',
      );
    } on firebase.FirebaseAuthException catch (e) {
      final safeMsg = _mapResetPasswordError(e.code);
      _setErrorMessage(safeMsg);

      if (e.code == 'user-not-found') {
        return OperationResult.completed(
          message:
              'Se houver uma conta com este e-mail, você receberá as instruções para redefinir sua senha.',
        );
      }
      return OperationResult.failed(
        rawErrorCode: e.code,
        safeError: safeMsg,
      );
    } catch (e) {
      const safeMsg =
          'Não foi possível solicitar a recuperação. Tente novamente mais tarde.';
      _setErrorMessage(safeMsg);
      return OperationResult.failed(
        rawErrorCode: 'unknown',
        safeError: safeMsg,
      );
    } finally {
      _currentOperation = AuthOperation.none;
      notifyListeners();
    }
  }

  Future<UpdateUserResult> updateUser({
    required String name,
    String? phoneNumber,
    String? avatarPath,
    String? newPassword,
    bool? enableIncomes,
    bool? appLocked,
    bool? enableSuppliers,
    int? themeColor,
  }) async {
    if (_currentUser == null) {
      return const UpdateUserResult(
        profileUpdated: false,
        errorMessage: 'Nenhum usuário logado.',
      );
    }
    if (_currentOperation != AuthOperation.none) {
      return const UpdateUserResult(
        profileUpdated: false,
        errorMessage: 'Uma operação já está em andamento.',
      );
    }

    _currentOperation = AuthOperation.updateProfile;
    _setErrorMessage(null);
    notifyListeners();

    bool profileSaved = false;
    bool? passwordSaved;
    bool requiresRecentLogin = false;
    String? error;

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        phoneNumber: phoneNumber,
        avatarPath: avatarPath,
        enableIncomes: enableIncomes,
        appLocked: appLocked,
        enableSuppliers: enableSuppliers,
        themeColor: themeColor,
      );
      if (appLocked != null) {
        AppSecurityService.setSecure(appLocked);
      }
      await _authRepository.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      profileSaved = true;

      if (newPassword != null && newPassword.isNotEmpty) {
        try {
          await _authRepository
              .getCurrentFirebaseUser()
              ?.updatePassword(newPassword);
          passwordSaved = true;
        } on firebase.FirebaseAuthException catch (e) {
          passwordSaved = false;
          if (e.code == 'requires-recent-login') {
            requiresRecentLogin = true;
            error =
                'Por segurança, faça login novamente antes de alterar sua senha.';
          } else if (e.code == 'weak-password') {
            error = 'A nova senha informada é muito fraca.';
          } else {
            error = 'Erro ao atualizar senha: ${e.message ?? e.code}';
          }
        } catch (e) {
          passwordSaved = false;
          error = 'Erro inesperado ao atualizar a senha.';
        }
      }

      notifyListeners();
      return UpdateUserResult(
        profileUpdated: profileSaved,
        passwordUpdated: passwordSaved,
        requiresRecentLogin: requiresRecentLogin,
        errorMessage: error,
      );
    } catch (e) {
      _setErrorMessage('Erro ao atualizar perfil.');
      return UpdateUserResult(
        profileUpdated: profileSaved,
        passwordUpdated: passwordSaved,
        requiresRecentLogin: requiresRecentLogin,
        errorMessage: error ?? 'Erro ao atualizar perfil.',
      );
    } finally {
      _currentOperation = AuthOperation.none;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context, dynamic ref) async {
    _currentOperation = AuthOperation.logout;
    notifyListeners();

    try {
      ref.read(dashboardViewModelProvider).clearData();
      ref.read(expenseViewModelProvider).clearData();
      ref.read(credentialViewModelProvider).clearData();
      ref.read(navigationViewModelProvider).clearData(notify: false);
      ref.read(categoryViewModelProvider).clearData();

      final uidToClear = _currentUser?.id;
      if (uidToClear != null && uidToClear.isNotEmpty) {
        await NotificationService.reconciler.cancelAllForSession(uidToClear);
      }
      await HomeWidgetService.clearWidgetData();

      await _authRepository.signOut();
      await _localAuthService.clearCredentials();

      _currentUser = null;
    } finally {
      _currentOperation = AuthOperation.none;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    _userProfileSub?.cancel();
    super.dispose();
  }

  String _mapResetPasswordError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns instantes antes de tentar novamente.';
      default:
        return 'Não foi possível solicitar a recuperação. Tente novamente mais tarde.';
    }
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
      case 'account-exists-with-different-credential':
        return 'Já existe uma conta com este email.';
      default:
        return 'Ocorreu um erro de autenticação.';
    }
  }
}

final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>(
  (ref) => AuthViewModel(
    authRepository: ref.read(authRepositoryProvider),
  ),
);
