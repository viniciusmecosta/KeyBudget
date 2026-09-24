import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/view/main_screen.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/main_bottom_navigation_bar.dart';
import 'package:key_budget/app/widgets/tab_selection_transition.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/view/expenses_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/suppliers/repository/supplier_repository.dart';
import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';

class FakeAuthRepo extends Fake implements AuthRepository {}
class FakeExpenseRepo extends Fake implements ExpenseRepository {}
class FakeCredentialRepo extends Fake implements CredentialRepository {}
class FakeSupplierRepo extends Fake implements SupplierRepository {}

class FakeAuthVM extends AuthViewModel {
  final User? mockUser;
  FakeAuthVM({this.mockUser})
      : super(authRepository: FakeAuthRepo(), listenToAuthChanges: false);

  @override
  User? get currentUser => mockUser;
}

class FakeCategoryVM extends CategoryViewModel {
  @override
  Future<void> fetchCategories(String userId) async {}
}

class FakeExpenseVM extends ExpenseViewModel {
  FakeExpenseVM() : super(repository: FakeExpenseRepo());

  @override
  bool get isLoading => false;

  @override
  void listenToExpenses(String userId) {}

  @override
  void setEnableIncomes(bool enabled) {}
}

class FakeCredentialVM extends CredentialViewModel {
  FakeCredentialVM() : super(repository: FakeCredentialRepo());

  @override
  void listenToCredentials(String userId) {}
}

class FakeSupplierVM extends SupplierViewModel {
  FakeSupplierVM() : super(repository: FakeSupplierRepo());

  @override
  void listenToSuppliers(String userId) {}
}

class FakeDocumentVM extends ChangeNotifier with Fake implements DocumentViewModel {
  @override
  void listenToDocuments(String userId) {}

  @override
  void setListKey(GlobalKey<SliverAnimatedListState> key) {}

  @override
  bool get isLoading => false;

  @override
  List<Document> get currentDisplayItems => const [];
}

class FakeDashboardVM extends DashboardViewModel {
  FakeDashboardVM({
    required super.categoryViewModel,
    required super.expenseViewModel,
    required super.credentialViewModel,
  });

  @override
  bool get isLoading => false;

  @override
  int get credentialCount => 0;

  @override
  double get totalAmountForMonth => 0.0;

  @override
  double get totalIncomeForMonth => 0.0;

  @override
  double get balanceForMonth => 0.0;
}

class _CounterStatefulTab extends StatefulWidget {
  const _CounterStatefulTab();

  @override
  State<_CounterStatefulTab> createState() => _CounterStatefulTabState();
}

class _CounterStatefulTabState extends State<_CounterStatefulTab> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Counter: $_counter'),
        ElevatedButton(
          onPressed: () => setState(() => _counter++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}

Widget createMainScreenTestWidget({
  required NavigationViewModel navVM,
  required AuthViewModel authVM,
  ThemeData? theme,
  bool disableAnimations = false,
}) {
  final categoryVM = FakeCategoryVM();
  final expenseVM = FakeExpenseVM();
  final credentialVM = FakeCredentialVM();
  final supplierVM = FakeSupplierVM();
  final documentVM = FakeDocumentVM();
  final dashboardVM = FakeDashboardVM(
    categoryViewModel: categoryVM,
    expenseViewModel: expenseVM,
    credentialViewModel: credentialVM,
  );

  return ProviderScope(
    overrides: [
      authViewModelProvider.overrideWith((ref) => authVM),
      navigationViewModelProvider.overrideWith((ref) => navVM),
      categoryViewModelProvider.overrideWith((ref) => categoryVM),
      expenseViewModelProvider.overrideWith((ref) => expenseVM),
      credentialViewModelProvider.overrideWith((ref) => credentialVM),
      supplierViewModelProvider.overrideWith((ref) => supplierVM),
      documentViewModelProvider.overrideWith((ref) => documentVM),
      dashboardViewModelProvider.overrideWith((ref) => dashboardVM),
    ],
    child: MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
          child: child!,
        );
      },
      home: const MainScreen(),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('MainScreen & TabSelectionTransition', () {
    testWidgets('MainScreen animates revisits without duplicating a first-visit animation', (tester) async {
      final navVM = NavigationViewModel();
      final authVM = FakeAuthVM(
        mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com'),
      );

      await tester.pumpWidget(
        createMainScreenTestWidget(navVM: navVM, authVM: authVM),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final transitionFinder = find.byType(TabSelectionTransition);
      expect(transitionFinder, findsOneWidget);
      final transitionState = tester.state<TabSelectionTransitionState>(transitionFinder);

      expect(transitionState.controller.value, 1.0);
      expect(transitionState.controller.isAnimating, isFalse);

      navVM.navigateTo(AppDestination.expenses);
      await tester.pump();

      expect(transitionState.controller.value, 1.0);
      expect(transitionState.controller.isAnimating, isFalse);
      await tester.pumpAndSettle();
      expect(transitionState.controller.value, 1.0);
      expect(transitionState.controller.isAnimating, isFalse);

      navVM.navigateTo(AppDestination.dashboard);
      await tester.pump();

      expect(transitionState.controller.isAnimating, isTrue);
      await tester.pumpAndSettle();
      expect(transitionState.controller.value, 1.0);
      expect(transitionState.controller.isAnimating, isFalse);

      navVM.navigateTo(AppDestination.expenses);
      await tester.pump();

      expect(transitionState.controller.isAnimating, isTrue);
      await tester.pumpAndSettle();
      expect(transitionState.controller.value, 1.0);
      expect(transitionState.controller.isAnimating, isFalse);
    });

    testWidgets('TabSelectionTransition preserves child state across revision switches', (tester) async {
      int activeIndex = 0;
      int revision = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: TabSelectionTransition(
                  revision: revision,
                  child: IndexedStack(
                    index: activeIndex,
                    children: const [
                      _CounterStatefulTab(),
                      Text('Tab 2 Content'),
                    ],
                  ),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      activeIndex = activeIndex == 0 ? 1 : 0;
                      revision++;
                    });
                  },
                  child: const Text('Toggle'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Counter: 0'), findsOneWidget);
      await tester.tap(find.text('Increment'));
      await tester.pumpAndSettle();
      expect(find.text('Counter: 1'), findsOneWidget);

      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();
      expect(find.text('Tab 2 Content'), findsOneWidget);

      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();
      expect(find.text('Counter: 1'), findsOneWidget);
    });

    testWidgets('transition keeps child state when enabled and reduced motion change', (tester) async {
      bool enabled = true;
      bool reducedMotion = false;
      late StateSetter update;

      await tester.pumpWidget(MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
              child: Scaffold(
                body: TabSelectionTransition(
                  revision: 0,
                  enabled: enabled,
                  child: const _CounterStatefulTab(),
                ),
              ),
            );
          },
        ),
      ));
      await tester.tap(find.text('Increment'));
      await tester.pump();

      update(() => enabled = false);
      await tester.pump();
      expect(find.text('Counter: 1'), findsOneWidget);

      update(() {
        enabled = true;
        reducedMotion = true;
      });
      await tester.pump();
      expect(find.text('Counter: 1'), findsOneWidget);

      update(() => reducedMotion = false);
      await tester.pump();
      expect(find.text('Counter: 1'), findsOneWidget);
    });

    testWidgets('reduced motion renders child immediately without transition animation', (tester) async {
      int revision = 0;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: TabSelectionTransition(
                  revision: revision,
                  child: const Text('Reduced Motion Tab Content'),
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => revision++),
                  child: const Text('Next'),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final transitionFinder = find.byType(TabSelectionTransition);
      expect(
        find.descendant(of: transitionFinder, matching: find.byType(FadeTransition)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: transitionFinder, matching: find.byType(SlideTransition)),
        findsOneWidget,
      );
      expect(find.text('Reduced Motion Tab Content'), findsOneWidget);

      final transitionState = tester.state<TabSelectionTransitionState>(transitionFinder);
      expect(transitionState.controller.value, 1.0);
      expect(transitionState.controller.isAnimating, isFalse);

      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(transitionState.controller.isAnimating, isFalse);
      expect(transitionState.controller.value, 1.0);
      expect(
        find.descendant(of: transitionFinder, matching: find.byType(FadeTransition)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: transitionFinder, matching: find.byType(SlideTransition)),
        findsOneWidget,
      );
      expect(find.text('Reduced Motion Tab Content'), findsOneWidget);
    });

    testWidgets('screen resize and theme rebuild do not restart transition controller', (tester) async {
      final navVM = NavigationViewModel();
      final authVM = FakeAuthVM(
        mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com'),
      );

      tester.view.physicalSize = const Size(599, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      ThemeData currentTheme = AppTheme.lightTheme;

      await tester.pumpWidget(
        createMainScreenTestWidget(
          navVM: navVM,
          authVM: authVM,
          theme: currentTheme,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final transitionFinder = find.byType(TabSelectionTransition);
      final transitionState = tester.state<TabSelectionTransitionState>(transitionFinder);
      expect(navVM.selectionRevision, 0);
      expect(transitionState.controller.isAnimating, isFalse);
      expect(transitionState.controller.value, 1.0);

      tester.view.physicalSize = const Size(600, 800);
      await tester.pump();
      expect(navVM.selectionRevision, 0);
      expect(transitionState.controller.isAnimating, isFalse);
      expect(transitionState.controller.value, 1.0);

      tester.view.physicalSize = const Size(840, 800);
      await tester.pump();
      expect(navVM.selectionRevision, 0);
      expect(transitionState.controller.isAnimating, isFalse);
      expect(transitionState.controller.value, 1.0);

      currentTheme = AppTheme.darkTheme;
      await tester.pumpWidget(
        createMainScreenTestWidget(
          navVM: navVM,
          authVM: authVM,
          theme: currentTheme,
        ),
      );
      await tester.pump();
      expect(navVM.selectionRevision, 0);
      expect(transitionState.controller.isAnimating, isFalse);
      expect(transitionState.controller.value, 1.0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(transitionState.controller.isAnimating, isFalse);
      expect(transitionState.controller.value, 1.0);
    });

    testWidgets('expense tab state survives phone and tablet breakpoint changes', (tester) async {
      tester.view.physicalSize = const Size(599, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final navVM = NavigationViewModel();
      navVM.navigateTo(AppDestination.expenses);
      final authVM = FakeAuthVM(
        mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com'),
      );
      await tester.pumpWidget(createMainScreenTestWidget(navVM: navVM, authVM: authVM));
      await tester.pumpAndSettle();
      final state = tester.state(find.byType(ExpensesScreen));

      tester.view.physicalSize = const Size(600, 800);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(ExpensesScreen)), same(state));

      tester.view.physicalSize = const Size(840, 800);
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(ExpensesScreen)), same(state));
    });

    testWidgets('tapping suppliers and profile with suppliers enabled triggers transitions and updates destination', (tester) async {
      tester.view.physicalSize = const Size(500, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final navVM = NavigationViewModel();
      navVM.updateSuppliersAvailability(true);

      final authVM = FakeAuthVM(
        mockUser: User(
          id: 'u1',
          name: 'Tester',
          email: 't@t.com',
          enableSuppliers: true,
        ),
      );

      await tester.pumpWidget(
        createMainScreenTestWidget(navVM: navVM, authVM: authVM),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final transitionFinder = find.byType(TabSelectionTransition);
      final transitionState = tester.state<TabSelectionTransitionState>(transitionFinder);
      expect(transitionState.controller.isAnimating, isFalse);

      expect(find.byType(GButton), findsNWidgets(6));

      await tester.tap(find.byType(GButton).at(4));
      await tester.pump();
      expect(transitionState.controller.isAnimating, isFalse);
      await tester.pumpAndSettle();
      expect(navVM.currentDestination, AppDestination.suppliers);
      expect(transitionState.controller.isAnimating, isFalse);

      await tester.tap(find.byType(GButton).at(5));
      await tester.pump();
      expect(transitionState.controller.isAnimating, isFalse);
      await tester.pumpAndSettle();
      expect(navVM.currentDestination, AppDestination.profile);
      expect(transitionState.controller.isAnimating, isFalse);

      await tester.tap(find.byType(GButton).at(4));
      await tester.pump();
      expect(transitionState.controller.isAnimating, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('six destinations fit on a narrow phone with large text', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final navVM = NavigationViewModel();
      navVM.updateSuppliersAvailability(true);
      final authVM = FakeAuthVM(
        mockUser: User(
          id: 'u1',
          name: 'Tester',
          email: 't@t.com',
          enableSuppliers: true,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            navigationViewModelProvider.overrideWith((ref) => navVM),
            authViewModelProvider.overrideWith((ref) => authVM),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: const Scaffold(bottomNavigationBar: MainBottomNavigationBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Fornecedores'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Fornecedores'));
      await tester.pumpAndSettle();
      expect(navVM.currentDestination, AppDestination.suppliers);
      expect(tester.takeException(), isNull);
    });
  });
}
