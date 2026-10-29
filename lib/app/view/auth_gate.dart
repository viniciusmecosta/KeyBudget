import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:passfin/app/view/main_screen.dart';
import 'package:passfin/core/services/app_lock_service.dart';
import 'package:passfin/features/auth/view/login_screen.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/app/view/startup_screen.dart';

enum AuthStatus { pending, success, failed }

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  AuthStatus _status = AuthStatus.pending;
  bool _isAuthenticating = false;

  @override
  Widget build(BuildContext context) {
    final authViewModel = ref.watch(authViewModelProvider);
    final appLockService = ref.watch(appLockServiceProvider);

    if (appLockService.justUnlocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(appLockServiceProvider).consumeJustUnlocked();
          if (_status != AuthStatus.success) {
            setState(() {
              _status = AuthStatus.success;
            });
          }
        }
      });
    }

    if (authViewModel.currentUser != null &&
        !_isAuthenticating &&
        !appLockService.isLocked &&
        !appLockService.justUnlocked &&
        _status == AuthStatus.pending) {
      _authenticateOrBypass();
    }

    if (authViewModel.currentUser == null && _status != AuthStatus.pending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _status = AuthStatus.pending;
          });
        }
      });
    }

    if (appLockService.isLocked && _status != AuthStatus.success) {
      return const StartupScreen();
    }

    if (!authViewModel.isInitialized) {
      return const StartupScreen();
    }

    if (authViewModel.currentUser == null) {
      return const LoginScreen(key: ValueKey('loginScreen'));
    }

    switch (_status) {
      case AuthStatus.success:
        return MainScreen(key: ValueKey(authViewModel.currentUser!.id));
      case AuthStatus.failed:
        return const AppPageScaffold(
          body: Center(child: Text("Falha na autenticação")),
        );
      case AuthStatus.pending:
        return const StartupScreen();
    }
  }

  void _authenticateOrBypass() {
    if (_isAuthenticating) return;
    _isAuthenticating = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appLockService = ref.read(appLockServiceProvider);
      final authViewModel = ref.read(authViewModelProvider);

      final appLocked = authViewModel.currentUser?.appLocked ?? true;
      if (!appLocked) {
        if (mounted) setState(() => _status = AuthStatus.success);
        if (mounted) _isAuthenticating = false;
        return;
      }

      if (authViewModel.justAuthenticated) {
        authViewModel.consumeJustAuthenticated();
        if (mounted) setState(() => _status = AuthStatus.success);
      } else {
        appLockService.lockApp();
        if (mounted) setState(() => _status = AuthStatus.pending);
      }

      if (mounted) {
        _isAuthenticating = false;
      }
    });
  }
}
