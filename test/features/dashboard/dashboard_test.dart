import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/view/dashboard_screen.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/dashboard/widgets/dashboard_balance_card.dart';
import 'package:key_budget/features/dashboard/widgets/dashboard_header.dart';
import 'package:key_budget/features/dashboard/widgets/quick_actions_section.dart';
import 'package:key_budget/features/dashboard/widgets/recent_activity_section.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class FakeAuthRepo extends Fake implements AuthRepository {}
class FakeExpenseRepo extends Fake implements ExpenseRepository {}
class FakeCredentialRepo extends Fake implements CredentialRepository {}

class FakeCategoryVM extends CategoryViewModel {
  @override
  Future<void> fetchCategories(String userId) async {}
}

class FakeExpenseVM extends ExpenseViewModel {
  FakeExpenseVM() : super(repository: FakeExpenseRepo());

  @override
  void listenToExpenses(String userId) {}
}

class FakeCredentialVM extends CredentialViewModel {
  FakeCredentialVM() : super(repository: FakeCredentialRepo());

  @override
  void listenToCredentials(String userId) {}
}

class FakeAuthVM extends AuthViewModel {
  final User? mockUser;
  FakeAuthVM({this.mockUser})
      : super(authRepository: FakeAuthRepo(), listenToAuthChanges: false);

  @override
  User? get currentUser => mockUser;
}

class FakeDashboardVM extends DashboardViewModel {
  final List<Expense> testExpenses;
  final List<Expense> testRecentExpenses;
  final double testTotalAmount;
  final double testBalance;
  final double testTotalIncome;
  final int testCredentialCount;

  FakeDashboardVM({
    this.testExpenses = const [],
    this.testRecentExpenses = const [],
    this.testTotalAmount = 1500.50,
    this.testBalance = 2500.75,
    this.testTotalIncome = 4000.0,
    this.testCredentialCount = 12,
  }) : super(
          categoryViewModel: FakeCategoryVM(),
          expenseViewModel: FakeExpenseVM(),
          credentialViewModel: FakeCredentialVM(),
        );

  @override
  List<Expense> get allExpenses => testExpenses;

  @override
  List<Expense> getRecentExpenses(bool enableIncomes) => testRecentExpenses;

  @override
  double get totalAmountForMonth => testTotalAmount;

  @override
  double get balanceForMonth => testBalance;

  @override
  double get totalIncomeForMonth => testTotalIncome;

  @override
  int get credentialCount => testCredentialCount;

  @override
  bool get isLoading => false;

  @override
  double averageOfPreviousMonths(bool enableIncomes) => 1200.0;

  @override
  double percentageChangeFromAverage(bool enableIncomes) => 15.0;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('Dashboard Components & Responsive Layout', () {
    testWidgets('DashboardHeader handles 60-char name without overflow and navigates to profile', (tester) async {
      final navVM = NavigationViewModel();
      final authVM = FakeAuthVM(
        mockUser: User(
          id: 'u1',
          name: 'Alexandre Bernardo dos Santos Medeiros da Silva Pereira Costa',
          email: 'alexandre@test.com',
        ),
      );

      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => authVM),
            navigationViewModelProvider.overrideWith((ref) => navVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: DashboardHeader(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Alexandre Bernardo'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(navVM.currentDestination, AppDestination.profile);
    });

    testWidgets('DashboardBalanceCard displays expenses when enableIncomes is false', (tester) async {
      final navVM = NavigationViewModel();
      final authVMIncomesDisabled = FakeAuthVM(
        mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com', enableIncomes: false),
      );
      final dashboardVM = FakeDashboardVM();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => authVMIncomesDisabled),
            dashboardViewModelProvider.overrideWith((ref) => dashboardVM),
            navigationViewModelProvider.overrideWith((ref) => navVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardBalanceCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Despesas do mês'), findsOneWidget);
      expect(find.textContaining(r'R$'), findsWidgets);
      expect(find.textContaining('Receitas:'), findsNothing);
    });

    testWidgets('DashboardBalanceCard displays balance and totals when enableIncomes is true', (tester) async {
      final navVM = NavigationViewModel();
      final authVMIncomesEnabled = FakeAuthVM(
        mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com', enableIncomes: true),
      );
      final dashboardVM = FakeDashboardVM();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => authVMIncomesEnabled),
            dashboardViewModelProvider.overrideWith((ref) => dashboardVM),
            navigationViewModelProvider.overrideWith((ref) => navVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DashboardBalanceCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saldo do período'), findsOneWidget);
      expect(find.textContaining('Receitas:'), findsOneWidget);
      expect(find.textContaining('Despesas:'), findsOneWidget);
    });

    testWidgets('QuickActionsSection renders actions and navigates to credentials', (tester) async {
      final navVM = NavigationViewModel();
      final authVM = FakeAuthVM(
        mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com', enableSuppliers: true),
      );
      final dashboardVM = FakeDashboardVM();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => authVM),
            dashboardViewModelProvider.overrideWith((ref) => dashboardVM),
            navigationViewModelProvider.overrideWith((ref) => navVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: QuickActionsSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nova despesa'), findsOneWidget);
      expect(find.text('Credenciais'), findsOneWidget);
      expect(find.text('Análise'), findsOneWidget);
      expect(find.text('Fornecedores'), findsOneWidget);

      await tester.tap(find.text('Credenciais'));
      await tester.pumpAndSettle();
      expect(navVM.currentDestination, AppDestination.credentials);
    });

    testWidgets('RecentActivitySection renders empty account state', (tester) async {
      final navVM = NavigationViewModel();
      final authVM = FakeAuthVM(
        mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com', enableIncomes: false),
      );
      final emptyAccountVM = FakeDashboardVM(
        testExpenses: [],
        testRecentExpenses: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => authVM),
            dashboardViewModelProvider.overrideWith((ref) => emptyAccountVM),
            navigationViewModelProvider.overrideWith((ref) => navVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RecentActivitySection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma transação registrada'), findsOneWidget);
      expect(find.text('Adicionar despesa'), findsOneWidget);
    });

    testWidgets('RecentActivitySection keeps its action visible with 200% text', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => FakeAuthVM(
              mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com'),
            )),
            dashboardViewModelProvider.overrideWith((ref) => FakeDashboardVM()),
            navigationViewModelProvider.overrideWith((ref) => NavigationViewModel()),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const Scaffold(body: SingleChildScrollView(child: RecentActivitySection())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Ver todas'), findsOneWidget);
    });

    testWidgets('RecentActivitySection renders empty month state with historical link', (tester) async {
      final navVM = NavigationViewModel();
      final authVM = FakeAuthVM(
        mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com', enableIncomes: false),
      );
      final historicalExpense = Expense(
        id: 'exp_old',
        location: 'Mercado',
        amount: 50.0,
        date: DateTime.now().subtract(const Duration(days: 60)),
        categoryId: 'cat_1',
      );
      final emptyMonthVM = FakeDashboardVM(
        testExpenses: [historicalExpense],
        testRecentExpenses: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => authVM),
            dashboardViewModelProvider.overrideWith((ref) => emptyMonthVM),
            navigationViewModelProvider.overrideWith((ref) => navVM),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RecentActivitySection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sem lançamentos neste mês'), findsOneWidget);
      expect(find.text('Ver histórico completo'), findsOneWidget);

      await tester.tap(find.text('Ver histórico completo'));
      await tester.pumpAndSettle();
      expect(navVM.currentDestination, AppDestination.expenses);
    });

    testWidgets('DashboardScreen renders 2-column layout on wide screen', (tester) async {
      final navVM = NavigationViewModel();
      final authVM = FakeAuthVM(
        mockUser: User(id: 'u1', name: 'Tester', email: 't@t.com'),
      );
      final categoryVM = FakeCategoryVM();
      final expenseVM = FakeExpenseVM();
      final credentialVM = FakeCredentialVM();
      final dashboardVM = FakeDashboardVM();

      tester.view.physicalSize = const Size(1024, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith((ref) => authVM),
            categoryViewModelProvider.overrideWith((ref) => categoryVM),
            expenseViewModelProvider.overrideWith((ref) => expenseVM),
            credentialViewModelProvider.overrideWith((ref) => credentialVM),
            dashboardViewModelProvider.overrideWith((ref) => dashboardVM),
            navigationViewModelProvider.overrideWith((ref) => navVM),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final balanceCardFinder = find.byType(DashboardBalanceCard);
      final recentActivityFinder = find.byType(RecentActivitySection);

      expect(balanceCardFinder, findsOneWidget);
      expect(recentActivityFinder, findsOneWidget);

      final balanceCardTopLeft = tester.getTopLeft(balanceCardFinder);
      final recentActivityTopLeft = tester.getTopLeft(recentActivityFinder);

      expect(recentActivityTopLeft.dx, greaterThan(balanceCardTopLeft.dx));
    });
  });
}
