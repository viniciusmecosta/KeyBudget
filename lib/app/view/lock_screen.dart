import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:provider/provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    final localAuthService = LocalAuthService();
    final isAuthenticated = await localAuthService.authenticate();
    if (isAuthenticated && mounted) {
      Provider.of<AppLockService>(context, listen: false).unlockApp();
    }
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Desbloquear'),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 250.ms),
    );
  }
}
