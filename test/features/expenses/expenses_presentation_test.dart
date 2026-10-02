import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:key_budget/app/widgets/activity_tile_widget.dart';
import 'package:key_budget/app/widgets/category_picker_field.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/domain/recurrence_schedule.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';
import 'package:key_budget/features/expenses/view/expenses_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/expenses/widgets/category_filter_modal.dart';
import 'package:key_budget/features/expenses/widgets/expense_form.dart';

class FakeAuthRepo extends Fake implements AuthRepository {}

class FakeCategoryVM extends CategoryViewModel {
  final List<ExpenseCategory> mockCategories;
  FakeCategoryVM(this.mockCategories);

  @override
  List<ExpenseCategory> get categories => mockCategories;

  @override
  ExpenseCategory? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return mockCategories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> fetchCategories(String userId) async {}
}

class ColdStartCategoryVM extends FakeCategoryVM {
  ColdStartCategoryVM(this.loadedCategories) : super([]);

  final List<ExpenseCategory> loadedCategories;
  int fetchCount = 0;

  @override
  Future<void> fetchCategories(String userId) async {
    fetchCount++;
    mockCategories.addAll(loadedCategories);
    notifyListeners();
  }
}

class FakeAuthVM extends AuthViewModel {
  final User? mockUser;
  FakeAuthVM({this.mockUser})
      : super(authRepository: FakeAuthRepo(), listenToAuthChanges: false);

  @override
  User? get currentUser => mockUser;
}

class FakeExpenseVM extends ExpenseViewModel {
  final List<Expense> initialExpenses;
  FakeExpenseVM({this.initialExpenses = const []}) {
    allExpenses = initialExpenses;
  }

  @override
  bool get isLoading => false;

  @override
  List<Expense> get currentDisplayItems => filteredExpenses;

  @override
  void listenToExpenses(String userId) {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  final List<ExpenseCategory> testCategories = [
    ExpenseCategory(
      id: 'cat_1',
      name: 'Alimentação',
      colorValue: Colors.blue.toARGB32(),
      iconCodePoint: Icons.fastfood.codePoint,
    ),
    ExpenseCategory(
      id: 'cat_2',
      name: 'Transporte',
      colorValue: Colors.orange.toARGB32(),
      iconCodePoint: Icons.directions_car.codePoint,
    ),
  ];

  final testUser = User(
    id: 'u1',
    name: 'Test User',
    email: 'test@example.com',
    enableIncomes: true,
  );

  Widget createTestApp({
    required Widget child,
    ExpenseViewModel? expenseVM,
    CategoryViewModel? categoryVM,
    AuthViewModel? authVM,
  }) {
    return ProviderScope(
      overrides: [
        if (expenseVM != null) expenseViewModelProvider.overrideWith((ref) => expenseVM),
        if (categoryVM != null) categoryViewModelProvider.overrideWith((ref) => categoryVM),
        if (authVM != null) authViewModelProvider.overrideWith((ref) => authVM),
      ],
      child: MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('direct expense launch loads categories before selection', (tester) async {
    final categories = ColdStartCategoryVM(testCategories);
    await tester.pumpWidget(
      createTestApp(
        child: const AddExpenseScreen(),
        expenseVM: FakeExpenseVM(),
        categoryVM: categories,
        authVM: FakeAuthVM(mockUser: testUser),
      ),
    );
    await tester.pumpAndSettle();

    expect(categories.fetchCount, 1);
    await tester.ensureVisible(find.byType(CategoryPickerField));
    await tester.tap(find.byType(CategoryPickerField));
    await tester.pumpAndSettle();
    expect(find.text('Selecione uma Categoria'), findsOneWidget);
    expect(find.text('Alimentação'), findsOneWidget);
    await tester.tap(find.text('Alimentação'));
    await tester.pumpAndSettle();
    expect(find.text('Selecione uma Categoria'), findsNothing);
    expect(find.text('Alimentação'), findsOneWidget);
  });

  group('ActivityTile Badges', () {
    testWidgets('renders compact scheduled icon when expense date is in the future', (tester) async {
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final expense = Expense(
        id: 'e1',
        amount: 50.0,
        date: futureDate,
        categoryId: 'cat_1',
        location: 'Mercado Futuro',
      );

      await tester.pumpWidget(
        createTestApp(
          child: ActivityTile(expense: expense, index: 0),
          categoryVM: FakeCategoryVM(testCategories),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Agendado'), findsNothing);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });

    testWidgets('renders installment badge when installment info is present', (tester) async {
      final expense = Expense(
        id: 'e2',
        amount: 100.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        categoryId: 'cat_2',
        currentInstallment: 2,
        totalInstallments: 5,
        location: 'Notebook',
      );

      await tester.pumpWidget(
        createTestApp(
          child: ActivityTile(expense: expense, index: 0),
          categoryVM: FakeCategoryVM(testCategories),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parcela 2 de 5'), findsOneWidget);
    });

    testWidgets('renders recurring badge when recurringExpenseId is present', (tester) async {
      final expense = Expense(
        id: 'e3',
        amount: 30.0,
        date: DateTime.now().subtract(const Duration(days: 1)),
        categoryId: 'cat_1',
        recurringExpenseId: 'rec_123',
        location: 'Assinatura Streaming',
      );

      await tester.pumpWidget(
        createTestApp(
          child: ActivityTile(expense: expense, index: 0),
          categoryVM: FakeCategoryVM(testCategories),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recorrente'), findsOneWidget);
    });
  });

  group('CategoryFilterModal Lifecycle and Isolation', () {
    testWidgets('applies selected category and income filters atomically on submit', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final expenseVM = FakeExpenseVM();

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  builder: (_) => const CategoryFilterModal(),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
          expenseVM: expenseVM,
          categoryVM: FakeCategoryVM(testCategories),
          authVM: FakeAuthVM(mockUser: testUser),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Filtros'), findsOneWidget);

      await tester.tap(find.text('Receitas'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Alimentação'));
      await tester.pumpAndSettle();

      expect(find.text('Aplicar (2)'), findsOneWidget);
      expect(find.text('2 selecionados'), findsOneWidget);

      await tester.tap(find.text('Aplicar (2)'));
      await tester.pumpAndSettle();

      expect(expenseVM.filterIsIncome, isTrue);
      expect(expenseVM.selectedCategoryIds, contains('cat_1'));
      expect(expenseVM.hasActiveFilters, isTrue);
    });

    testWidgets('clearing filters in modal resets selection without auto-applying', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final expenseVM = FakeExpenseVM();
      expenseVM.setFilters(categories: ['cat_1'], type: false);

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: ctx,
                  isScrollControlled: true,
                  builder: (_) => const CategoryFilterModal(),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
          expenseVM: expenseVM,
          categoryVM: FakeCategoryVM(testCategories),
          authVM: FakeAuthVM(mockUser: testUser),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('2 selecionados'), findsOneWidget);

      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();

      expect(find.text('2 selecionados'), findsNothing);
      expect(find.text('Aplicar'), findsOneWidget);

      expect(expenseVM.filterIsIncome, isFalse);
      expect(expenseVM.selectedCategoryIds, contains('cat_1'));

      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(expenseVM.filterIsIncome, isNull);
      expect(expenseVM.selectedCategoryIds, isEmpty);
      expect(expenseVM.hasActiveFilters, isFalse);
    });
  });

  group('ExpensesScreen Presentation & Dynamic Labels', () {
    testWidgets('shows dynamic Saldo filtrado label and active chips when filter is on and incomes enabled', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final expense = Expense(
        id: 'e1',
        amount: 80.0,
        date: now,
        categoryId: 'cat_1',
        location: 'Restaurante',
      );
      final expenseVM = FakeExpenseVM(initialExpenses: [expense]);
      expenseVM.setFilters(categories: ['cat_1']);

      await tester.pumpWidget(
        createTestApp(
          child: const ExpensesScreen(),
          expenseVM: expenseVM,
          categoryVM: FakeCategoryVM(testCategories),
          authVM: FakeAuthVM(mockUser: testUser),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saldo filtrado'), findsOneWidget);
      expect(find.text('Alimentação'), findsWidgets);

      final chipDeleteIcon = find.byIcon(Icons.close);
      expect(chipDeleteIcon, findsOneWidget);

      await tester.tap(chipDeleteIcon);
      await tester.pumpAndSettle();

      expect(expenseVM.selectedCategoryIds, isEmpty);
      expect(find.text('Saldo filtrado'), findsNothing);
      expect(find.text('Saldo do mês'), findsOneWidget);
    });

    testWidgets('shows dynamic Total filtrado label when filter is on and incomes disabled', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final userWithoutIncomes = User(
        id: 'u2',
        name: 'No Incomes User',
        email: 'user2@example.com',
        enableIncomes: false,
      );

      final now = DateTime.now();
      final expense = Expense(
        id: 'e1',
        amount: 80.0,
        date: now,
        categoryId: 'cat_1',
        location: 'Restaurante',
      );
      final expenseVM = FakeExpenseVM(initialExpenses: [expense]);
      expenseVM.setFilters(categories: ['cat_1']);

      await tester.pumpWidget(
        createTestApp(
          child: const ExpensesScreen(),
          expenseVM: expenseVM,
          categoryVM: FakeCategoryVM(testCategories),
          authVM: FakeAuthVM(mockUser: userWithoutIncomes),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total filtrado'), findsOneWidget);
    });
  });

  group('ExpenseForm Installment Distribution Preview', () {
    test('formats installment preview with exact cents distribution', () {
      final text = ExpenseForm.formatInstallmentDistribution(Money.fromCents(10000), 3);
      expect(text, '1 de R\$ 33,34 e 2 de R\$ 33,33');

      final textEven = ExpenseForm.formatInstallmentDistribution(Money.fromCents(9000), 3);
      expect(textEven, '3 de R\$ 30,00');
    });
  });

  group('Recurrence Next Candidate Preview', () {
    test('calculates sequential upcoming candidate dates', () {
      final tempRule = RecurringExpense(
        amount: 50.0,
        amountMinor: 5000,
        startDate: DateTime(2026, 3, 15),
        frequency: RecurrenceFrequency.monthly,
        dayOfMonth: 15,
        scheduleVersion: 1,
      );

      final candidate1 = RecurrenceSchedule.getNextCandidateDate(rule: tempRule, cursor: null);
      expect(candidate1, isNotNull);
      final candidate2 = RecurrenceSchedule.getNextCandidateDate(rule: tempRule, cursor: candidate1);
      expect(candidate2, isNotNull);
      final candidate3 = RecurrenceSchedule.getNextCandidateDate(rule: tempRule, cursor: candidate2);
      expect(candidate3, isNotNull);

      expect(candidate1!.day, 15);
      expect(candidate1.month, 3);
      expect(candidate2!.day, 15);
      expect(candidate2.month, 4);
      expect(candidate3!.day, 15);
      expect(candidate3.month, 5);
    });
  });
}
