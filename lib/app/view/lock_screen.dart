import 'package:flutter/material.dart';
import 'package:key_budget/app/utils/app_animations.dart';
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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          _authenticate();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _authenticate();
    } else if (state == AppLifecycleState.paused) {
      LocalAuthService().stopAuthentication();
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) {
      return;
    }

    setState(() => _isAuthenticating = true);

    final localAuthService = LocalAuthService();
    final isAuthenticated = await localAuthService.authenticate();

    if (!mounted) {
      return;
    }

    if (isAuthenticated) {
      Provider.of<AppLockService>(context, listen: false).unlockApp();
    } else {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: AppAnimations.fadeIn(Center(
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
              onPressed: _isAuthenticating
                  ? null
                  : () {
                      _authenticate();
                    },
              icon: _isAuthenticating
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.onPrimary,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.fingerprint),
              label: const Text('Desbloquear'),
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
              label: Text('Sair',
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          ],
        ),
      )),
    );
  }
}
