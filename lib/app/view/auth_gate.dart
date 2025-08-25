import 'package:flutter/material.dart';
import 'package:key_budget/app/view/auth_wrapper.dart';
import 'package:key_budget/features/auth/view/login_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (authViewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: authViewModel.currentUser != null
          ? AuthWrapper(key: ValueKey(authViewModel.currentUser))
          : LoginScreen(key: const ValueKey('loginScreen')),
    );
  }
}
