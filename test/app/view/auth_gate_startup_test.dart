import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/app/view/lock_screen.dart';
import 'package:passfin/app/view/startup_screen.dart';
import 'package:passfin/core/models/user_model.dart';
import 'package:passfin/core/services/app_lock_service.dart';
import 'package:passfin/features/auth/repository/auth_repository.dart';
import 'package:passfin/features/auth/view/login_screen.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/features/dashboard/widgets/dashboard_skeleton.dart';
import 'package:passfin/main.dart';

class _AuthRepository extends Fake implements AuthRepository {}

class _Auth extends AuthViewModel {
  _Auth()
    : super(authRepository: _AuthRepository(), listenToAuthChanges: false);
  bool initialized = false;
  User? user;
  @override
  bool get isInitialized => initialized;
  @override
  User? get currentUser => user;
  @override
  bool get justAuthenticated => false;
  void resolve(User? value) {
    user = value;
    initialized = true;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const home = MethodChannel('home_widget');
  const updates = MethodChannel('home_widget/updates');
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(home, (_) async => null);
    messenger.setMockMethodCallHandler(updates, (_) async => null);
  });
  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(home, null);
    messenger.setMockMethodCallHandler(updates, null);
  });

  testWidgets(
    'startup resolves a locked account without showing the dashboard',
    (tester) async {
      final auth = _Auth();
      final lock = AppLockService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => auth),
            appLockServiceProvider.overrideWith((ref) => lock),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(StartupScreen), findsOneWidget);
      expect(find.byType(DashboardSkeleton), findsNothing);
      auth.resolve(
        User(
          id: 'owner',
          name: 'Teste',
          email: 'teste@example.com',
          appLocked: true,
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(lock.isLocked, isTrue);
      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.byType(DashboardSkeleton), findsNothing);
      expect(find.text('PassFin bloqueado'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    },
  );

  testWidgets(
    'signed out startup goes to login without dashboard placeholders',
    (tester) async {
      final auth = _Auth();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authViewModelProvider.overrideWith((ref) => auth)],
          child: const MyApp(),
        ),
      );
      await tester.pump();
      auth.resolve(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);
      expect(find.byType(DashboardSkeleton), findsNothing);
    },
  );
}
