import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/core/services/local_auth_service.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/auth/view/forgot_password_screen.dart';
import 'package:key_budget/features/auth/view/login_screen.dart';
import 'package:key_budget/features/auth/view/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class FakeLocalAuthentication extends Fake implements LocalAuthentication {
  bool isDeviceSupportedValue = true;
  bool canCheckBiometricsValue = true;
  List<BiometricType> biometrics = [BiometricType.fingerprint];
  bool authenticateResult = true;
  PlatformException? throwOnAuth;

  @override
  Future<bool> isDeviceSupported() async => isDeviceSupportedValue;

  @override
  Future<bool> get canCheckBiometrics async => canCheckBiometricsValue;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => biometrics;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    if (throwOnAuth != null) throw throwOnAuth!;
    return authenticateResult;
  }

  @override
  Future<bool> stopAuthentication() async => true;
}

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> store = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      store[key] = value;
    } else {
      store.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    store.remove(key);
  }
}

class FakeAuthRepository extends Fake implements AuthRepository {
  final List<String> resetEmailsSent = [];
  String? lastLoginEmail;
  String? lastLoginPassword;
  String? lastRegisterName;
  String? lastRegisterEmail;
  String? lastRegisterPassword;
  String? lastRegisterPhone;
  String? lastRegisterAvatar;
  bool throwOnReset = false;
  String resetErrorCode = 'user-not-found';
  bool throwOnLogin = false;
  bool throwOnRegister = false;
  bool failProfileSetupOnce = false;
  String registerErrorCode = 'email-already-in-use';
  bool hasProfile = true;

  @override
  Stream<firebase.User?> get firebaseAuthStateChanges => const Stream.empty();

  @override
  Stream<User?> getUserProfileStream(String uid) => Stream.value(
        User(id: uid, name: 'Tester', email: 'tester@test.com', appLocked: true),
      );

  @override
  Future<User?> getUserProfile(String uid) async => hasProfile
      ? User(id: uid, name: 'Tester', email: 'tester@test.com')
      : null;

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (throwOnReset) {
      throw firebase.FirebaseAuthException(code: resetErrorCode);
    }
    resetEmailsSent.add(email);
  }

  @override
  Future<firebase.UserCredential> signInWithEmail(String email, String password) async {
    lastLoginEmail = email;
    lastLoginPassword = password;
    if (throwOnLogin) {
      throw firebase.FirebaseAuthException(code: 'invalid-credential');
    }
    return FakeUserCredential();
  }

  @override
  Future<void> ensureCategoriesExist(String userId) async {}

  @override
  Future<User> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
    String? avatarPath,
  }) async {
    if (failProfileSetupOnce) {
      failProfileSetupOnce = false;
      throw const ProfileSetupException();
    }
    if (throwOnRegister) {
      throw firebase.FirebaseAuthException(code: registerErrorCode);
    }
    lastRegisterName = name;
    lastRegisterEmail = email;
    lastRegisterPassword = password;
    lastRegisterPhone = phoneNumber;
    lastRegisterAvatar = avatarPath;
    return User(id: 'test_uid_123', name: name, email: email);
  }
}

class FakeUserCredential extends Fake implements firebase.UserCredential {
  @override
  firebase.User? get user => FakeFirebaseUser();
}

class FakeFirebaseUser extends Fake implements firebase.User {
  @override
  String get uid => 'test_uid_123';
  @override
  String? get email => 'tester@test.com';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAuthService tests', () {
    late FakeLocalAuthentication fakeAuth;
    late FakeSecureStorage fakeStorage;
    late LocalAuthService service;

    setUp(() {
      fakeAuth = FakeLocalAuthentication();
      fakeStorage = FakeSecureStorage();
      service = LocalAuthService(auth: fakeAuth, storage: fakeStorage);
    });

    test('canAuthenticate detects device support or biometric capability', () async {
      fakeAuth.isDeviceSupportedValue = true;
      fakeAuth.canCheckBiometricsValue = false;
      expect(await service.canAuthenticate(), isTrue);

      fakeAuth.isDeviceSupportedValue = false;
      fakeAuth.canCheckBiometricsValue = false;
      expect(await service.canAuthenticate(), isFalse);
    });

    test('checkAvailability distinguishes supported, deviceCredentialOnly and notSupported', () async {
      fakeAuth.isDeviceSupportedValue = true;
      fakeAuth.biometrics = [BiometricType.fingerprint];
      expect(await service.checkAvailability(), LocalAuthAvailability.supported);

      fakeAuth.biometrics = [];
      fakeAuth.isDeviceSupportedValue = true;
      expect(await service.checkAvailability(), LocalAuthAvailability.deviceCredentialOnly);

      fakeAuth.isDeviceSupportedValue = false;
      fakeAuth.canCheckBiometricsValue = false;
      expect(await service.checkAvailability(), LocalAuthAvailability.notSupported);
    });

    test('authenticateLocal maps status codes accurately', () async {
      fakeAuth.authenticateResult = true;
      expect(await service.authenticateLocal(), LocalAuthResult.success);

      fakeAuth.authenticateResult = false;
      expect(await service.authenticateLocal(), LocalAuthResult.cancelled);

      fakeAuth.throwOnAuth = PlatformException(code: 'LockedOut');
      expect(await service.authenticateLocal(), LocalAuthResult.temporarilyLockedOut);

      fakeAuth.throwOnAuth = PlatformException(code: 'PermanentlyLockedOut');
      expect(await service.authenticateLocal(), LocalAuthResult.permanentlyLockedOut);
    });

    test('saveCredentials does not store password to secure storage (retired)', () async {
      await service.saveCredentials('test@test.com', 'secret_pwd');
      expect(await service.getCredentials(), isNull);
    });

    test('clearCredentials purges existing storage keys safely', () async {
      fakeStorage.store['last_user_email'] = 'test@test.com';
      fakeStorage.store['last_user_password'] = 'secret_pwd';
      await service.clearCredentials();
      expect(fakeStorage.store.containsKey('last_user_email'), isFalse);
      expect(fakeStorage.store.containsKey('last_user_password'), isFalse);
    });
  });

  group('AuthViewModel tests', () {
    late FakeAuthRepository fakeRepo;
    late LocalAuthService localAuthService;
    late AuthViewModel viewModel;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      localAuthService = LocalAuthService(
        auth: FakeLocalAuthentication(),
        storage: FakeSecureStorage(),
      );
      viewModel = AuthViewModel(
        authRepository: fakeRepo,
        localAuthService: localAuthService,
        listenToAuthChanges: false,
      );
    });

    test('sendPasswordResetEmail gives neutral success response and trims email', () async {
      final res = await viewModel.sendPasswordResetEmail('  user@domain.com  ');
      expect(res.isSuccess, isTrue);
      expect(fakeRepo.resetEmailsSent, contains('user@domain.com'));
      expect(res.message, contains('Se houver uma conta'));
    });

    test('sendPasswordResetEmail returns neutral message even on user-not-found', () async {
      fakeRepo.throwOnReset = true;
      fakeRepo.resetErrorCode = 'user-not-found';
      final res = await viewModel.sendPasswordResetEmail('unknown@domain.com');
      expect(res.isSuccess, isTrue);
      expect(res.message, contains('Se houver uma conta'));
    });

    test('sendPasswordResetEmail rejects invalid email format safely', () async {
      final res = await viewModel.sendPasswordResetEmail('notanemail');
      expect(res.isFailed, isTrue);
      expect(res.safeError, 'Informe um e-mail válido.');
    });

    test('loginUser preserves exact password without trim while trimming email', () async {
      const exactPassword = '  p@ssw0rd with spaces  ';
      await viewModel.loginUser(email: '  test@domain.com  ', password: exactPassword);
      expect(fakeRepo.lastLoginEmail, 'test@domain.com');
      expect(fakeRepo.lastLoginPassword, exactPassword);
    });

    test('registerUser preserves exact password without trim while trimming email', () async {
      const exactPassword = '  new_password_123  ';
      await viewModel.registerUser(
        name: 'John',
        email: '  john@domain.com  ',
        password: exactPassword,
      );
      expect(fakeRepo.lastRegisterEmail, 'john@domain.com');
      expect(fakeRepo.lastRegisterPassword, exactPassword);
    });

    test('registerUser can retry after profile setup fails', () async {
      fakeRepo.failProfileSetupOnce = true;
      final first = await viewModel.registerUser(
        name: 'Ana', email: 'ana@test.com', password: 'senha123',
      );
      expect(first, isFalse);
      expect(viewModel.errorMessage, contains('perfil ainda não foi salvo'));

      final retry = await viewModel.registerUser(
        name: 'Ana', email: 'ana@test.com', password: 'senha123',
      );
      expect(retry, isTrue);
      expect(viewModel.currentUser?.name, 'Ana');
    });

    test('loginUser explains how to finish a missing profile', () async {
      fakeRepo.hasProfile = false;
      final result = await viewModel.loginUser(
        email: 'ana@test.com', password: 'senha123',
      );
      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('cadastro está pendente'));
    });

    test('authenticateWithBiometrics returns false when no user is logged in', () async {

      final res = await viewModel.authenticateWithBiometrics();
      expect(res, isFalse);
    });
  });

  group('Widgets tests', () {
    testWidgets('ForgotPasswordScreen submits email and presents neutral confirmation', (tester) async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(
        authRepository: fakeRepo,
        listenToAuthChanges: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => vm),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(initialEmail: 'user@test.com'),
          ),
        ),
      );

      expect(find.text('user@test.com'), findsOneWidget);
      expect(find.text('Enviar E-mail'), findsOneWidget);

      await tester.tap(find.text('Enviar E-mail'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.resetEmailsSent, contains('user@test.com'));
      expect(find.textContaining('Se houver uma conta'), findsOneWidget);

      await tester.pump(const Duration(seconds: 35));
    });

    testWidgets('LoginScreen allows navigating to ForgotPasswordScreen', (tester) async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(
        authRepository: fakeRepo,
        listenToAuthChanges: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => vm),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Esqueceu sua senha?'), findsOneWidget);
      await tester.tap(find.text('Esqueceu sua senha?'));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    });

    testWidgets('LoginScreen renders brand, title, autofill fields and password toggle', (tester) async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(
        authRepository: fakeRepo,
        listenToAuthChanges: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => vm),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Entre na sua conta'), findsOneWidget);
      expect(find.text('Acesse suas finanças e informações em um só lugar.'), findsOneWidget);
      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);

      expect(find.byTooltip('Mostrar senha'), findsOneWidget);
      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();
      expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders hierarchy and toggles password visibility', (tester) async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(
        authRepository: fakeRepo,
        listenToAuthChanges: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => vm),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Crie sua conta'), findsOneWidget);
      expect(find.text('Comece com seus dados essenciais.'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Mínimo de 6 caracteres'), findsOneWidget);
      expect(find.text('Confirmar senha'), findsOneWidget);
      expect(find.text('Adicionar foto e telefone (opcional)'), findsOneWidget);
      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.text('Já tem uma conta?'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);

      final showPasswordFinder = find.byTooltip('Mostrar senha').first;
      await tester.tap(showPasswordFinder);
      await tester.pump();
      expect(find.byTooltip('Ocultar senha'), findsWidgets);
    });

    testWidgets('RegisterScreen validates essential fields on submit', (tester) async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(
        authRepository: fakeRepo,
        listenToAuthChanges: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => vm),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pumpAndSettle();

      expect(find.text('Insira seu nome completo'), findsOneWidget);
      expect(find.text('Insira seu e-mail'), findsOneWidget);
      expect(find.text('Informe sua senha'), findsOneWidget);
      expect(fakeRepo.lastRegisterEmail, isNull);
    });

    testWidgets('RegisterScreen expands and collapses optional section preserving data', (tester) async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(
        authRepository: fakeRepo,
        listenToAuthChanges: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => vm),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Telefone (opcional)'), findsNothing);

      await tester.ensureVisible(find.text('Adicionar foto e telefone (opcional)'));
      await tester.tap(find.text('Adicionar foto e telefone (opcional)'));
      await tester.pumpAndSettle();

      expect(find.text('Telefone (opcional)'), findsOneWidget);

      await tester.ensureVisible(find.widgetWithText(TextField, 'Telefone (opcional)'));
      await tester.enterText(find.widgetWithText(TextField, 'Telefone (opcional)'), '11987654321');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Foto e telefone (adicionados)'));
      await tester.tap(find.text('Foto e telefone (adicionados)'));
      await tester.pumpAndSettle();

      expect(find.text('Telefone (opcional)'), findsNothing);
      expect(find.text('1 adicionado'), findsOneWidget);

      await tester.ensureVisible(find.text('Foto e telefone (adicionados)'));
      await tester.tap(find.text('Foto e telefone (adicionados)'));
      await tester.pumpAndSettle();

      expect(find.text('Telefone (opcional)'), findsOneWidget);
      expect(find.text('(11) 98765-4321'), findsOneWidget);
    });

    testWidgets('RegisterScreen registers successfully with only essential fields', (tester) async {
      final fakeRepo = FakeAuthRepository();
      final vm = AuthViewModel(
        authRepository: fakeRepo,
        listenToAuthChanges: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => vm),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Nome completo'), 'Alice Silva');
      await tester.enterText(find.widgetWithText(TextField, 'E-mail'), 'alice@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Senha'), 'secret123');
      await tester.enterText(find.widgetWithText(TextField, 'Confirmar senha'), 'secret123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(fakeRepo.lastRegisterName, 'Alice Silva');
      expect(fakeRepo.lastRegisterEmail, 'alice@example.com');
      expect(fakeRepo.lastRegisterPassword, 'secret123');
      expect(fakeRepo.lastRegisterPhone, isNull);
      expect(fakeRepo.lastRegisterAvatar, isNull);
    });

    testWidgets('RegisterScreen shows inline error when email is already in use', (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.throwOnRegister = true;
      fakeRepo.registerErrorCode = 'email-already-in-use';
      final vm = AuthViewModel(
        authRepository: fakeRepo,
        listenToAuthChanges: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => vm),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Nome completo'), 'Bob Silva');
      await tester.enterText(find.widgetWithText(TextField, 'E-mail'), 'bob@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Senha'), 'secret123');
      await tester.enterText(find.widgetWithText(TextField, 'Confirmar senha'), 'secret123');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Criar conta'));
      await tester.tap(find.text('Criar conta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('já existe', findRichText: true), findsWidgets);
      expect(find.text('Entrar com esta conta'), findsOneWidget);
    });
  });
}
