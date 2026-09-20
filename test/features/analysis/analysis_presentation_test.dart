import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/analysis/view/analysis_screen.dart';
import 'package:key_budget/features/analysis/widgets/category_analysis_section_widget.dart';
import 'package:key_budget/features/analysis/widgets/monthly_trend_section_widget.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class FakeAuthRepo extends Fake implements AuthRepository {}
class FakeExpenseRepo extends Fake implements ExpenseRepository {}

class FakeCategoryVM extends CategoryViewModel {
  final List<ExpenseCategory> mockCategories;
  FakeCategoryVM(this.mockCategories);

  @override
  List<ExpenseCategory> get categories => mockCategories;

  @override
  bool get isLoading => false;

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

class FakeAuthVM extends AuthViewModel {
  final User? mockUser;
  FakeAuthVM({this.mockUser})
      : super(authRepository: FakeAuthRepo(), listenToAuthChanges: false);

  @override
  User? get currentUser => mockUser;
}

class FakeExpenseVM extends ExpenseViewModel {
  final List<Expense> initialExpenses;
  FakeExpenseVM({this.initialExpenses = const []})
      : super(repository: FakeExpenseRepo()) {
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

  group('ChartScaleHelper Algorithms', () {
    test('calculates 1, 2, 5 x 10^k readable ticks accurately', () {
      final scale1 = ChartScaleHelper.calculateNiceScale(
        minVal: 0,
        maxVal: 3450,
        targetTicks: 5,
      );
      expect(scale1.min, 0.0);
      expect(scale1.interval, 500.0);
      expect(scale1.max, 3500.0);

      final scale2 = ChartScaleHelper.calculateNiceScale(
        minVal: 0,
        maxVal: 8200,
        targetTicks: 5,
      );
      expect(scale2.min, 0.0);
      expect(scale2.interval, 2000.0);
      expect(scale2.max, 10000.0);
    });

    test('handles zero and negative ranges stably without division by zero', () {
      final zeroScale = ChartScaleHelper.calculateNiceScale(
        minVal: 0,
        maxVal: 0,
      );
      expect(zeroScale.min, 0.0);
      expect(zeroScale.max, 100.0);
      expect(zeroScale.interval, 25.0);
    });

    test('formats compact axis values cleanly', () {
      expect(ChartScaleHelper.formatCompactValue(0), '0');
      expect(ChartScaleHelper.formatCompactValue(450), '450');
      expect(ChartScaleHelper.formatCompactValue(1500), '1.5k');
      expect(ChartScaleHelper.formatCompactValue(2000), '2k');
      expect(ChartScaleHelper.formatCompactValue(1000000), '1M');
      expect(ChartScaleHelper.formatCompactValue(-2500), '-2.5k');
    });

    test('limits visible horizontal labels to at most 6 simultaneously preserving ends', () {
      final shortIndices = ChartScaleHelper.calculateVisibleLabelIndices(4);
      expect(shortIndices, {0, 1, 2, 3});

      final yearIndices = ChartScaleHelper.calculateVisibleLabelIndices(12);
      expect(yearIndices.length, lessThanOrEqualTo(6));
      expect(yearIndices.contains(0), isTrue);
      expect(yearIndices.contains(11), isTrue);

      final twoYearIndices = ChartScaleHelper.calculateVisibleLabelIndices(24);
      expect(twoYearIndices.length, lessThanOrEqualTo(6));
      expect(twoYearIndices.contains(0), isTrue);
      expect(twoYearIndices.contains(23), isTrue);
    });
  });

  final testCategories = List.generate(8, (i) {
    return ExpenseCategory(
      id: 'cat_$i',
      name: 'Categoria $i',
      colorValue: (0xFF100000 + i * 0x001122).toInt(),
      iconCodePoint: Icons.category.codePoint,
    );
  });

  final testUser = User(
    id: 'u1',
    name: 'Analyst User',
    email: 'user@example.com',
    enableIncomes: true,
  );

  Widget createTestApp({
    required Widget child,
    required ExpenseViewModel expenseVM,
    required CategoryViewModel categoryVM,
    required AuthViewModel authVM,
  }) {
    return ProviderScope(
      overrides: [
        expenseViewModelProvider.overrideWith((ref) => expenseVM),
        categoryViewModelProvider.overrideWith((ref) => categoryVM),
        authViewModelProvider.overrideWith((ref) => authVM),
      ],
      child: MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
  }

  group('CategoryAnalysisSectionWidget Presentation', () {
    testWidgets('groups categories exceeding 5 into Outras with expand toggle', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final expenses = List.generate(8, (i) {
        return Expense(
          id: 'exp_$i',
          amount: (100.0 - i * 10),
          date: DateTime(now.year, now.month, 5),
          categoryId: 'cat_$i',
          location: 'Despesa $i',
        );
      });

      final expenseVM = FakeExpenseVM(initialExpenses: expenses);
      final categoryVM = FakeCategoryVM(testCategories);
      final authVM = FakeAuthVM(mockUser: testUser);

      await tester.pumpWidget(
        createTestApp(
          child: const SingleChildScrollView(
            child: CategoryAnalysisSectionWidget(),
          ),
          expenseVM: expenseVM,
          categoryVM: categoryVM,
          authVM: authVM,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Composição de Gastos'), findsOneWidget);
      expect(find.text('Ver todas (8)'), findsOneWidget);
      expect(find.text('Outras categorias (3)'), findsOneWidget);

      await tester.tap(find.text('Ver todas (8)'));
      await tester.pumpAndSettle();

      expect(find.text('Mostrar top 5'), findsOneWidget);
      expect(find.text('Categoria 7'), findsOneWidget);
    });

    testWidgets('displays empty chart state when total expenses are zero', (tester) async {
      final expenseVM = FakeExpenseVM(initialExpenses: []);
      final categoryVM = FakeCategoryVM(testCategories);
      final authVM = FakeAuthVM(mockUser: testUser);

      await tester.pumpWidget(
        createTestApp(
          child: const CategoryAnalysisSectionWidget(),
          expenseVM: expenseVM,
          categoryVM: categoryVM,
          authVM: authVM,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma despesa para exibir no período'), findsOneWidget);
    });
  });

  group('MonthlyTrendSectionWidget Presentation & Data Table Alternative', () {
    testWidgets('toggles accessible data table alternative with exact currency points', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final expenses = [
        Expense(
          id: 'e1',
          amount: 250.0,
          date: DateTime(now.year, now.month - 1, 10),
          categoryId: 'cat_0',
          location: 'Despesa Anterior',
        ),
        Expense(
          id: 'e2',
          amount: 500.0,
          date: DateTime(now.year, now.month, 12),
          categoryId: 'cat_1',
          location: 'Despesa Atual',
        ),
      ];

      final expenseVM = FakeExpenseVM(initialExpenses: expenses);
      final categoryVM = FakeCategoryVM(testCategories);
      final authVM = FakeAuthVM(mockUser: testUser);

      await tester.pumpWidget(
        createTestApp(
          child: const SingleChildScrollView(
            child: MonthlyTrendSectionWidget(),
          ),
          expenseVM: expenseVM,
          categoryVM: categoryVM,
          authVM: authVM,
        ),
      );
      await tester.pumpAndSettle();

      final toggleButton = find.text('Ver dados em tabela');
      expect(toggleButton, findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(find.text('Ocultar tabela'), findsOneWidget);
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Receitas'), findsWidgets);
      expect(find.text('Despesas'), findsWidgets);
      expect(find.text('Saldo'), findsWidgets);
    });
  });

  group('AnalysisScreen Export Modal Integration', () {
    testWidgets('opens export options bottom sheet showing PDF and CSV choices for all users', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final expenseVM = FakeExpenseVM(initialExpenses: []);
      final categoryVM = FakeCategoryVM(testCategories);
      final authVM = FakeAuthVM(mockUser: testUser);

      await tester.pumpWidget(
        createTestApp(
          child: const AnalysisScreen(),
          expenseVM: expenseVM,
          categoryVM: categoryVM,
          authVM: authVM,
        ),
      );
      await tester.pumpAndSettle();

      final exportButton = find.byIcon(Icons.share_outlined);
      expect(exportButton, findsOneWidget);

      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      expect(find.text('Exportar Análise'), findsOneWidget);
      expect(find.text('Relatório em PDF'), findsOneWidget);
      expect(find.text('Planilha em CSV'), findsOneWidget);
    });

    testWidgets('AnalysisScreen resets selectedMonthForCategory to current month on entry', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final expenseVM = FakeExpenseVM(initialExpenses: [
        Expense(
          id: 'e_past',
          amount: 100.0,
          date: DateTime(2025, 1, 1),
          categoryId: 'cat_1',
          location: 'Passado',
        ),
      ]);
      final categoryVM = FakeCategoryVM(testCategories);
      final authVM = FakeAuthVM(mockUser: testUser);

      final analysisVM = AnalysisViewModel(
        categoryViewModel: categoryVM,
        expenseViewModel: expenseVM,
      );
      analysisVM.setSelectedMonthForCategory(DateTime(2025, 1));
      expect(analysisVM.selectedMonthForCategory, equals(DateTime(2025, 1)));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseViewModelProvider.overrideWith((ref) => expenseVM),
            categoryViewModelProvider.overrideWith((ref) => categoryVM),
            authViewModelProvider.overrideWith((ref) => authVM),
            analysisViewModelProvider.overrideWith((ref) => analysisVM),
          ],
          child: const MaterialApp(
            home: AnalysisScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      expect(
        analysisVM.selectedMonthForCategory,
        equals(DateTime(now.year, now.month)),
      );
    });
  });
}
