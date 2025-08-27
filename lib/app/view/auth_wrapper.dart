import 'package:flutter/material.dart';
import 'package:key_budget/app/view/main_screen.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';

enum AuthStatus { pending, success, failed }

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthStatus _status = AuthStatus.pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    final localAuthService = LocalAuthService();
    final canAuth = await localAuthService.canAuthenticate();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    if (!canAuth) {
      if (mounted) {
        await authViewModel.logout(context);
      }
      return;
    }

    final isAuthenticated = await localAuthService.authenticate();

    if (mounted) {
      setState(() {
        _status = isAuthenticated ? AuthStatus.success : AuthStatus.failed;
      });

      if (_status == AuthStatus.failed) {
        await authViewModel.logout(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case AuthStatus.success:
        return const MainScreen();
      case AuthStatus.failed:
      case AuthStatus.pending:
      default:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
