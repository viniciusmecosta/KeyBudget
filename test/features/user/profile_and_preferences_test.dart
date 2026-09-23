import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/suppliers/repository/supplier_repository.dart';
import 'package:key_budget/features/suppliers/view/suppliers_screen.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';
import 'package:key_budget/features/user/view/user_screen.dart';
import 'package:key_budget/features/user/widgets/settings_tile.dart';

class MockAuthRepository extends Fake implements AuthRepository {
  User? lastUpdatedUser;

  @override
  Future<void> updateUserProfile(User user) async {
    lastUpdatedUser = user;
  }
}

class MockSupplierRepository extends Fake implements SupplierRepository {
  @override
  Stream<List<Supplier>> getSuppliersStreamForUser(String userId) =>
      const Stream.empty();
}

class RecoveringSupplierRepository extends Fake implements SupplierRepository {
  int attempts = 0;

  @override
  Stream<List<Supplier>> getSuppliersStreamForUser(String userId) {
    attempts++;
    if (attempts == 1) {
      return Stream.error(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
    }
    return Stream.value([Supplier(id: '1', name: 'Mercado')]);
  }
}

class TestAuthViewModel extends AuthViewModel {
  final MockAuthRepository mockRepo;

  TestAuthViewModel({required this.mockRepo, User? initialUser})
      : super(
          authRepository: mockRepo,
          listenToAuthChanges: false,
        ) {
    if (initialUser != null) {
      currentUser = initialUser;
    }
  }
}

class FakeSupplierViewModel extends SupplierViewModel {
  FakeSupplierViewModel({List<Supplier> suppliers = const []})
      : super(repository: MockSupplierRepository()) {
    setSuppliersForTesting(suppliers);
  }

  @override
  void listenToSuppliers(String userId) {}
}

class FakeExpenseViewModel extends Fake implements ExpenseViewModel {}

class FakeCategoryViewModel extends Fake implements CategoryViewModel {}

class FakeCredentialViewModel extends Fake implements CredentialViewModel {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('app_security'),
          (MethodCall methodCall) async => null,
        );
  });

  group('User Model screen capture protection truth table', () {
    test('theme mode defaults safely and preserves known values', () {
      final legacyUser = User(id: 'u1', name: 'User 1', email: 'u1@test.com');
      expect(legacyUser.effectiveThemeMode, 'system');

      final darkUser = legacyUser.copyWith(themeMode: 'dark');
      expect(darkUser.effectiveThemeMode, 'dark');
      expect(User.fromMap(darkUser.toMap()).effectiveThemeMode, 'dark');

      final invalidUser = legacyUser.copyWith(themeMode: 'unknown');
      expect(invalidUser.effectiveThemeMode, 'system');
    });

    test('effectiveProtectScreenCapture defaults to appLocked when null', () {
      final userWithLock = User(
        id: 'u1',
        name: 'User 1',
        email: 'u1@test.com',
        appLocked: true,
        protectScreenCapture: null,
      );
      expect(userWithLock.effectiveProtectScreenCapture, isTrue);

      final userWithoutLock = User(
        id: 'u2',
        name: 'User 2',
        email: 'u2@test.com',
        appLocked: false,
        protectScreenCapture: null,
      );
      expect(userWithoutLock.effectiveProtectScreenCapture, isFalse);

      final userDefault = User(
        id: 'u3',
        name: 'User 3',
        email: 'u3@test.com',
      );
      expect(userDefault.effectiveProtectScreenCapture, isTrue);
    });

    test('effectiveProtectScreenCapture prioritizes explicit protectScreenCapture value', () {
      final lockedButNoCapture = User(
        id: 'u1',
        name: 'User 1',
        email: 'u1@test.com',
        appLocked: true,
        protectScreenCapture: false,
      );
      expect(lockedButNoCapture.effectiveProtectScreenCapture, isFalse);

      final unlockedWithCapture = User(
        id: 'u2',
        name: 'User 2',
        email: 'u2@test.com',
        appLocked: false,
        protectScreenCapture: true,
      );
      expect(unlockedWithCapture.effectiveProtectScreenCapture, isTrue);
    });

    test('copyWith handles protectScreenCapture and clearProtectScreenCapture', () {
      final original = User(
        id: 'u1',
        name: 'User 1',
        email: 'u1@test.com',
        protectScreenCapture: true,
      );

      final updated = original.copyWith(protectScreenCapture: false);
      expect(updated.protectScreenCapture, isFalse);

      final cleared = updated.copyWith(clearProtectScreenCapture: true);
      expect(cleared.protectScreenCapture, isNull);
    });

    test('toMap and fromMap roundtrip protect_screen_capture correctly', () {
      final user = User(
        id: 'u1',
        name: 'User 1',
        email: 'u1@test.com',
        appLocked: false,
        protectScreenCapture: true,
      );

      final map = user.toMap();
      expect(map['protect_screen_capture'], isTrue);

      final parsed = User.fromMap(map);
      expect(parsed.protectScreenCapture, isTrue);
      expect(parsed.effectiveProtectScreenCapture, isTrue);
    });
  });

  group('AuthViewModel independent preference updating', () {
    test('updating appLocked when protectScreenCapture is null materializes prior effective value', () async {
      final mockRepo = MockAuthRepository();
      final initialUser = User(
        id: 'u1',
        name: 'User 1',
        email: 'u1@test.com',
        appLocked: true,
        protectScreenCapture: null,
      );
      final vm = TestAuthViewModel(mockRepo: mockRepo, initialUser: initialUser);

      await vm.updateUser(name: 'User 1', appLocked: false);

      expect(mockRepo.lastUpdatedUser, isNotNull);
      expect(mockRepo.lastUpdatedUser!.appLocked, isFalse);
      expect(mockRepo.lastUpdatedUser!.protectScreenCapture, isTrue);
      expect(mockRepo.lastUpdatedUser!.effectiveProtectScreenCapture, isTrue);
    });

    test('explicitly updating protectScreenCapture updates independently', () async {
      final mockRepo = MockAuthRepository();
      final initialUser = User(
        id: 'u1',
        name: 'User 1',
        email: 'u1@test.com',
        appLocked: true,
        protectScreenCapture: true,
      );
      final vm = TestAuthViewModel(mockRepo: mockRepo, initialUser: initialUser);

      await vm.updateUser(name: 'User 1', protectScreenCapture: false);

      expect(mockRepo.lastUpdatedUser!.appLocked, isTrue);
      expect(mockRepo.lastUpdatedUser!.protectScreenCapture, isFalse);
      expect(mockRepo.lastUpdatedUser!.effectiveProtectScreenCapture, isFalse);
    });
  });

  group('SupplierViewModel search filtering', () {
    test('reports offline loading failure and recovers after retry', () async {
      final repository = RecoveringSupplierRepository();
      final vm = SupplierViewModel(repository: repository);

      vm.listenToSuppliers('u1');
      await Future<void>.delayed(Duration.zero);
      expect(vm.hasLoadError, isTrue);
      expect(vm.isOffline, isTrue);

      vm.retryListenToSuppliers('u1');
      await Future<void>.delayed(Duration.zero);
      expect(repository.attempts, 2);
      expect(vm.hasLoadError, isFalse);
      expect(vm.allSuppliers.single.name, 'Mercado');
      vm.dispose();
    });

    test('filteredSuppliers filters by name, rep, phone, and email case-insensitively', () {
      final vm = SupplierViewModel(repository: MockSupplierRepository());
      final suppliers = [
        Supplier(
          id: '1',
          name: 'Supermercado Central',
          representativeName: 'Carlos Silva',
          phoneNumber: '11999998888',
          email: 'contato@central.com',
        ),
        Supplier(
          id: '2',
          name: 'Auto Peças Silva',
          representativeName: 'Marcos Oliveira',
          phoneNumber: '21988887777',
          email: 'pecas@silva.com',
        ),
        Supplier(
          id: '3',
          name: 'Farmácia Popular',
          representativeName: 'Juliana Costa',
          phoneNumber: '31977776666',
          email: 'contato@farmacia.com',
        ),
      ];

      vm.setSuppliersForTesting(suppliers);

      expect(vm.filteredSuppliers.length, 3);

      vm.setSearchQuery('central');
      expect(vm.filteredSuppliers.length, 1);
      expect(vm.filteredSuppliers.first.name, 'Supermercado Central');

      vm.setSearchQuery('silva');
      expect(vm.filteredSuppliers.length, 2);

      vm.setSearchQuery('97777');
      expect(vm.filteredSuppliers.length, 1);
      expect(vm.filteredSuppliers.first.name, 'Farmácia Popular');

      vm.setSearchQuery('pecas@');
      expect(vm.filteredSuppliers.length, 1);
      expect(vm.filteredSuppliers.first.name, 'Auto Peças Silva');

      vm.setSearchQuery('inexistente');
      expect(vm.filteredSuppliers, isEmpty);
    });
  });

  group('SuppliersScreen search interaction widgets', () {
    testWidgets('SuppliersScreen toggles search bar and renders empty state on no match', (tester) async {
      final mockRepo = MockAuthRepository();
      final user = User(id: 'u1', name: 'Tester', email: 'tester@test.com');
      final authVm = TestAuthViewModel(mockRepo: mockRepo, initialUser: user);
      final supplierVm = FakeSupplierViewModel(
        suppliers: [
          Supplier(id: '1', name: 'Padaria Alfa'),
          Supplier(id: '2', name: 'Açougue Beta'),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => authVm),
            supplierViewModelProvider.overrideWith((ref) => supplierVm),
          ],
          child: const MaterialApp(home: SuppliersScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Padaria Alfa'), findsOneWidget);
      expect(find.text('Açougue Beta'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Farmacia');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum fornecedor encontrado para a busca.'), findsOneWidget);
      expect(find.text('Limpar busca'), findsOneWidget);

      await tester.tap(find.text('Limpar busca'));
      await tester.pumpAndSettle();

      expect(find.text('Padaria Alfa'), findsOneWidget);
      expect(find.text('Açougue Beta'), findsOneWidget);
    });
  });

  group('UserScreen structured sections and independent toggles', () {
    testWidgets('renders all 6 sections and handles switches with single gesture arbitration', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockRepo = MockAuthRepository();
      final user = User(
        id: 'u1',
        name: 'Tester da Silva',
        email: 'tester@test.com',
        appLocked: true,
        protectScreenCapture: true,
        enableIncomes: false,
        enableSuppliers: true,
      );
      final authVm = TestAuthViewModel(mockRepo: mockRepo, initialUser: user);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => authVm),
            expenseViewModelProvider.overrideWith((ref) => FakeExpenseViewModel()),
            categoryViewModelProvider.overrideWith((ref) => FakeCategoryViewModel()),
            credentialViewModelProvider.overrideWith((ref) => FakeCredentialViewModel()),
          ],
          child: const MaterialApp(home: UserScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONTA'), findsOneWidget);
      expect(find.text('APARÊNCIA'), findsOneWidget);
      expect(find.text('RECURSOS'), findsOneWidget);
      expect(find.text('SEGURANÇA E PRIVACIDADE'), findsOneWidget);
      expect(find.text('DADOS E RECUPERAÇÃO'), findsOneWidget);
      expect(find.text('SESSÃO'), findsOneWidget);

      expect(find.text('Bloquear ao sair do aplicativo'), findsOneWidget);
      expect(find.text('Proteger captura de tela'), findsOneWidget);

      final switchTiles = find.byType(SettingsSwitchTile);
      expect(switchTiles, findsNWidgets(4));

      await tester.tap(find.text('Bloquear ao sair do aplicativo'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastUpdatedUser, isNotNull);
      expect(mockRepo.lastUpdatedUser!.appLocked, isFalse);
    });
  });
}
