import 'package:flutter/material.dart';
import 'package:key_budget/app/view/main_screen.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/features/auth/view/login_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';

enum AuthStatus { pending, success, failed }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthStatus _status = AuthStatus.pending;
  bool _isAuthenticating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (authViewModel.isInitialized &&
        authViewModel.currentUser != null &&
        !_isAuthenticating &&
        _status == AuthStatus.pending) {
      _isAuthenticating = true;
      _authenticateOrBypass();
    }
  }

  void _authenticateOrBypass() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.justAuthenticated) {
        authViewModel.consumeJustAuthenticated();
        if (mounted) setState(() => _status = AuthStatus.success);
      } else {
        await _authenticate();
      }
    });
  }

  Future<void> _authenticate() async {
    final localAuthService = LocalAuthService();
    final canAuth = await localAuthService.canAuthenticate();

    if (!canAuth) {
      if (mounted) setState(() => _status = AuthStatus.success);
      return;
    }

    final isAuthenticated = await localAuthService.authenticate();

    if (mounted) {
      setState(() {
        _status = isAuthenticated ? AuthStatus.success : AuthStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    if (!authViewModel.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authViewModel.currentUser == null) {
      return LoginScreen(key: const ValueKey('loginScreen'));
    }

    switch (_status) {
      case AuthStatus.success:
        return MainScreen(key: ValueKey(authViewModel.currentUser!.id));
      case AuthStatus.failed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<AppLockService>(context, listen: false).lockApp();
        });
        return const Scaffold(body: Center(child: Text("Falha na autenticação")));
      case AuthStatus.pending:
      default:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
