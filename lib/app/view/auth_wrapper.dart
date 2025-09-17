import 'package:flutter/material.dart';
import 'package:key_budget/app/view/main_screen.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
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

    if (!canAuth) {
      setState(() => _status = AuthStatus.success);
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
    switch (_status) {
      case AuthStatus.success:
        return const MainScreen();
      case AuthStatus.failed:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Provider.of<AppLockService>(context, listen: false).lockApp();
        });
        return const Scaffold(
          body: Center(),
        );
      case AuthStatus.pending:
      default:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
  }
}
