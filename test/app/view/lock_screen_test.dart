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
  int logoutAttempts = 0;

  @override
  Future<void> logout(BuildContext context, dynamic ref) async {
    logoutAttempts++;
    throw StateError("offline");
  }

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
  testWidgets('sign out requires confirmation and reports a failed attempt', (
    tester,
  ) async {
    final auth = _SignedInAuthViewModel();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authViewModelProvider.overrideWith((ref) => auth)],
        child: MaterialApp(
          home: LockScreen(localAuthService: _CancelledLocalAuthService()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair da Conta'));
    await tester.pumpAndSettle();
    expect(auth.logoutAttempts, 0);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(auth.logoutAttempts, 0);
    await tester.tap(find.text('Sair da Conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();
    expect(auth.logoutAttempts, 1);
    expect(
      find.text('Não foi possível sair da conta. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Desbloquear'), findsOneWidget);
  });

  testWidgets('lock screen remains usable in landscape with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith((ref) => _SignedInAuthViewModel()),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: LockScreen(localAuthService: _CancelledLocalAuthService()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Desbloquear'));
    await tester.pumpAndSettle();
    expect(find.text('Desbloquear'), findsOneWidget);
    expect(find.text('Sair da Conta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
    final localAuth = _CancelledLocalAuthService(
      result: LocalAuthResult.failed,
    );
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
