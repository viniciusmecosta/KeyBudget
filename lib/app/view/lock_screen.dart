import 'package:flutter/material.dart';
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80),
            const SizedBox(height: 24),
            const Text('KeyBudget está bloqueado',
                style: TextStyle(fontSize: 22)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Desbloquear'),
            ),
          ],
        ),
      ),
    );
  }
}
