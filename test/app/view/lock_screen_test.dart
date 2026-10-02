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
  _CancelledLocalAuthService({this.result = LocalAuthResult.cancelled});

  final LocalAuthResult result;
  int attempts = 0;

  @override
  Future<LocalAuthAvailability> checkAvailability() async =>
      LocalAuthAvailability.supported;

  @override
  Future<LocalAuthResult> authenticateLocal({
    String reason = 'Confirme sua identidade',
  }) async {
    attempts++;
    return result;
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
    expect(find.textContaining('Falha'), findsNothing);
    expect(find.textContaining('Não foi possível confirmar'), findsNothing);
    expect(find.textContaining('Sua privacidade'), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(localAuth.attempts, 1);

    await tester.tap(find.text('Desbloquear'));
    await tester.pump();
    expect(localAuth.attempts, 2);
  });

  testWidgets('real authentication failure shows a retry message', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final localAuth = _CancelledLocalAuthService(result: LocalAuthResult.failed);
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
    expect(
      find.text('Não foi possível confirmar. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Sair da Conta'), findsOneWidget);
  });
}
