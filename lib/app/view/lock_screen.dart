import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _authenticate();
      }
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) {
      return;
    }

    if (mounted) {
      setState(() {
        _isAuthenticating = true;
      });
    }

    final localAuthService = LocalAuthService();
    final isAuthenticated = await localAuthService.authenticate();

    if (mounted) {
      if (isAuthenticated) {
        Provider.of<AppLockService>(context, listen: false).unlockApp();
      } else {
        setState(() {
          _isAuthenticating = false;
        });
      }
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('KeyBudget está bloqueado',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isAuthenticating ? null : _authenticate,
              icon: _isAuthenticating
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.fingerprint),
              label: const Text('Desbloquear'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final authViewModel =
                    Provider.of<AuthViewModel>(context, listen: false);
                final appLockService =
                    Provider.of<AppLockService>(context, listen: false);

                await authViewModel.logout(context);

                appLockService.unlockApp();
              },
              icon:
                  Icon(Icons.logout, size: 20, color: theme.colorScheme.error),
              label: Text(
                'Sair',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side:
                    BorderSide(color: theme.colorScheme.error.withOpacity(0.4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
