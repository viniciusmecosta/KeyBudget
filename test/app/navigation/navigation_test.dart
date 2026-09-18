import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/main_bottom_navigation_bar.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class FakeAuthRepo extends Fake implements AuthRepository {}

class FakeAuthVM extends AuthViewModel {
  final bool suppliersEnabled;
  FakeAuthVM({this.suppliersEnabled = false})
      : super(authRepository: FakeAuthRepo(), listenToAuthChanges: false);

  @override
  User? get currentUser => User(
        id: 'user_123',
        name: 'User Test',
        email: 'user@test.com',
        enableSuppliers: suppliersEnabled,
      );
}

void main() {
  group('AppDestination & NavigationViewModel', () {
    test('available destinations count depends on enableSuppliers', () {
      final withoutSuppliers = AppDestination.getAvailable(enableSuppliers: false);
      expect(withoutSuppliers.length, 5);
      expect(withoutSuppliers.contains(AppDestination.suppliers), isFalse);
      expect(withoutSuppliers.last, AppDestination.profile);

      final withSuppliers = AppDestination.getAvailable(enableSuppliers: true);
      expect(withSuppliers.length, 6);
      expect(withSuppliers.contains(AppDestination.suppliers), isTrue);
    });

    test('navigateTo updates current and previous destinations', () {
      final vm = NavigationViewModel();
      expect(vm.currentDestination, AppDestination.dashboard);

      vm.navigateTo(AppDestination.expenses);
      expect(vm.currentDestination, AppDestination.expenses);
      expect(vm.previousDestination, AppDestination.dashboard);

      vm.navigateTo(AppDestination.credentials);
      expect(vm.currentDestination, AppDestination.credentials);
      expect(vm.previousDestination, AppDestination.expenses);
    });

    test('changing suppliers availability preserves profile or redirects suppliers', () {
      final vm = NavigationViewModel();
      vm.updateSuppliersAvailability(true);

      vm.navigateTo(AppDestination.profile);
      vm.updateSuppliersAvailability(false);
      expect(vm.currentDestination, AppDestination.profile);

      vm.updateSuppliersAvailability(true);
      vm.navigateTo(AppDestination.suppliers);
      expect(vm.currentDestination, AppDestination.suppliers);

      vm.updateSuppliersAvailability(false);
      expect(vm.currentDestination, AppDestination.dashboard);
    });

    test('selectedIndex delegates accurately to destination list', () {
      final vm = NavigationViewModel();
      vm.updateSuppliersAvailability(false);

      expect(vm.selectedIndex, 0);
      vm.selectedIndex = 1;
      expect(vm.currentDestination, AppDestination.expenses);

      vm.selectedIndex = 4;
      expect(vm.currentDestination, AppDestination.profile);
    });
  });

  group('MainBottomNavigationBar', () {
    testWidgets('renders 5 buttons and updates destination on tap', (tester) async {
      final navVM = NavigationViewModel();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => FakeAuthVM(suppliersEnabled: false)),
            navigationViewModelProvider.overrideWith((ref) => navVM),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              bottomNavigationBar: MainBottomNavigationBar(),
            ),
          ),
        ),
      );

      expect(find.byType(GButton), findsNWidgets(5));
      expect(find.text('Painel'), findsOneWidget);

      await tester.tap(find.byType(GButton).at(1));
      await tester.pumpAndSettle();
      expect(navVM.currentDestination, AppDestination.expenses);
    });

    testWidgets('shows modal sheet on 5th tab when suppliers are enabled', (tester) async {
      final navVM = NavigationViewModel();
      navVM.updateSuppliersAvailability(true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => FakeAuthVM(suppliersEnabled: true)),
            navigationViewModelProvider.overrideWith((ref) => navVM),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              bottomNavigationBar: MainBottomNavigationBar(),
            ),
          ),
        ),
      );

      expect(find.byType(GButton), findsNWidgets(5));

      await tester.tap(find.byType(GButton).at(4));
      await tester.pumpAndSettle();

      expect(find.text('Mais opções'), findsOneWidget);
      expect(find.text('Fornecedores'), findsOneWidget);

      await tester.tap(find.text('Fornecedores'));
      await tester.pumpAndSettle();

      expect(navVM.currentDestination, AppDestination.suppliers);
    });
  });
}
