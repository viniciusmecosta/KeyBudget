import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/app/view/lock_screen.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {}

class _SignedInAuthViewModel extends AuthViewModel {
  _SignedInAuthViewModel()
    : super(authRepository: _FakeAuthRepository(), listenToAuthChanges: false);

  @override
  User? get currentUser =>
      User(id: 'user', name: 'Teste', email: 'teste@example.com');
}

class _CancelledLocalAuthService extends LocalAuthService {
  int attempts = 0;

  @override
  Future<LocalAuthAvailability> checkAvailability() async =>
      LocalAuthAvailability.supported;

  @override
  Future<LocalAuthResult> authenticateLocal({
    String reason = 'Confirme sua identidade',
  }) async {
    attempts++;
    return LocalAuthResult.cancelled;
  }
}

void main() {
  testWidgets('cancelled prompt stays closed until unlock is tapped', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final localAuth = _CancelledLocalAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith((ref) => _SignedInAuthViewModel()),
        ],
        child: MaterialApp(home: LockScreen(localAuthService: localAuth)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(localAuth.attempts, 1);
    expect(find.text('Sair da Conta'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(localAuth.attempts, 1);

    await tester.tap(find.text('Desbloquear KeyBudget'));
    await tester.pump();
    expect(localAuth.attempts, 2);
  });
}
