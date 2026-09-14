import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/services/csv_service.dart';
import 'package:key_budget/core/time/app_clock.dart';
import 'package:key_budget/core/time/date_range.dart';
import 'package:key_budget/features/analysis/domain/analysis_calculator.dart';
import 'package:key_budget/features/analysis/domain/analysis_query.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class FakeAppClock implements AppClock {
  final DateTime _fixed;
  const FakeAppClock(this._fixed);

  @override
  DateTime now() => _fixed;
}

Expense _createExpense({
  required String id,
  required String motivation,
  required double amount,
  required DateTime date,
  String? categoryId,
  bool isIncome = false,
}) {
  return Expense(
    id: id,
    amount: amount,
    date: date,
    categoryId: categoryId,
    motivation: motivation,
    isIncome: isIncome,
    unmappedData: const {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixedClock = FakeAppClock(DateTime(2026, 6, 15, 12, 0, 0));
  final catAlimentacao = ExpenseCategory(
    id: 'cat_alim',
    name: 'Alimentação',
    iconCodePoint: Icons.fastfood.codePoint,
    colorValue: Colors.blue.toARGB32(),
  );
  final catTransporte = ExpenseCategory(
    id: 'cat_transp',
    name: 'Transporte',
    iconCodePoint: Icons.directions_bus.codePoint,
    colorValue: Colors.green.toARGB32(),
  );

  group('AnalysisCalculator - Regras Contábeis Puras e Determinísticas', () {
    test('Calcula receitas, despesas, saldo e média com precisão exata', () {
      final query = AnalysisQuery(
        range: DateRange(
          startInclusive: DateTime(2026, 4, 1),
          endExclusive: DateTime(2026, 7, 1),
        ),
      );

      final expenses = [

        _createExpense(
          id: 'e1',
          motivation: 'Mercado',
          amount: 150.50,
          date: DateTime(2026, 4, 10),
          categoryId: 'cat_alim',
        ),

        _createExpense(
          id: 'e2',
          motivation: 'Salário',
          amount: 5000.00,
          date: DateTime(2026, 5, 5),
          isIncome: true,
        ),
        _createExpense(
          id: 'e3',
          motivation: 'Metrô',
          amount: 49.50,
          date: DateTime(2026, 5, 20),
          categoryId: 'cat_transp',
        ),

        _createExpense(
          id: 'e4',
          motivation: 'Jantar',
          amount: 200.00,
          date: DateTime(2026, 6, 1),
          categoryId: 'cat_alim',
        ),
      ];

      final snapshot = AnalysisCalculator.calculate(
        query: query,
        expenses: expenses,
        categories: [catAlimentacao, catTransporte],
        capturedAt: fixedClock.now(),
      );

      expect(snapshot.totalExpenses, equals(Money.fromCents(40000)));

      expect(snapshot.totalIncomes, equals(Money.fromCents(500000)));

      expect(snapshot.balance, equals(Money.fromCents(460000)));

      expect(snapshot.averageMonthlyExpense.amountMinor, equals(13333));

      expect(snapshot.isBalanceExact, isTrue);
      expect(snapshot.isCategorySumExact, isTrue);
      expect(snapshot.isMonthlySeriesSumExact, isTrue);
      expect(snapshot.isInvariantsValid, isTrue);
    });

    test('Trata explicitamente despesas sem categoria e com categorias órfãs/removidas', () {
      final query = AnalysisQuery.forMonth(DateTime(2026, 6, 1));

      final expenses = [
        _createExpense(
          id: 'e1',
          motivation: 'Lanche',
          amount: 25.00,
          date: DateTime(2026, 6, 2),
          categoryId: null,
        ),
        _createExpense(
          id: 'e2',
          motivation: 'Assinatura Antiga',
          amount: 75.00,
          date: DateTime(2026, 6, 3),
          categoryId: 'cat_deletada_999',
        ),
        _createExpense(
          id: 'e3',
          motivation: 'Almoço',
          amount: 100.00,
          date: DateTime(2026, 6, 4),
          categoryId: 'cat_alim',
        ),
      ];

      final snapshot = AnalysisCalculator.calculate(
        query: query,
        expenses: expenses,
        categories: [catAlimentacao],
        capturedAt: fixedClock.now(),
      );

      expect(snapshot.totalExpenses, equals(Money.fromCents(20000)));
      expect(snapshot.categoryDistribution.length, equals(3));

      final uncategorizedGroup = snapshot.categoryDistribution.firstWhere(
        (g) => g.category.id == ExpenseCategory.uncategorized().id,
      );
      expect(uncategorizedGroup.totalAmount, equals(Money.fromCents(2500)));
      expect(uncategorizedGroup.percentage, closeTo(12.5, 0.01));

      final orphanGroup = snapshot.categoryDistribution.firstWhere(
        (g) => g.category.id == 'orphan_cat_deletada_999',
      );
      expect(orphanGroup.totalAmount, equals(Money.fromCents(7500)));
      expect(orphanGroup.percentage, closeTo(37.5, 0.01));

      final alimGroup = snapshot.categoryDistribution.firstWhere(
        (g) => g.category.id == 'cat_alim',
      );
      expect(alimGroup.totalAmount, equals(Money.fromCents(10000)));
      expect(alimGroup.percentage, closeTo(50.0, 0.01));

      expect(snapshot.isCategorySumExact, isTrue);
    });

    test('Série mensal preenche meses vazios continuamente sem pular datas', () {
      final query = AnalysisQuery(
        range: DateRange(
          startInclusive: DateTime(2026, 3, 1),
          endExclusive: DateTime(2026, 7, 1),
        ),
      );

      final expenses = [

        _createExpense(
          id: 'e1',
          motivation: 'Março Gasto',
          amount: 100.00,
          date: DateTime(2026, 3, 15),
          categoryId: 'cat_alim',
        ),
        _createExpense(
          id: 'e2',
          motivation: 'Junho Gasto',
          amount: 200.00,
          date: DateTime(2026, 6, 10),
          categoryId: 'cat_alim',
        ),
      ];

      final snapshot = AnalysisCalculator.calculate(
        query: query,
        expenses: expenses,
        categories: [catAlimentacao],
        capturedAt: fixedClock.now(),
      );

      expect(snapshot.monthlySeries.length, equals(4));
      expect(snapshot.monthlySeries[0].label, equals('2026-03'));
      expect(snapshot.monthlySeries[0].expenseAmount, equals(Money.fromCents(10000)));

      expect(snapshot.monthlySeries[1].label, equals('2026-04'));
      expect(snapshot.monthlySeries[1].expenseAmount, equals(Money.fromCents(0)));

      expect(snapshot.monthlySeries[2].label, equals('2026-05'));
      expect(snapshot.monthlySeries[2].expenseAmount, equals(Money.fromCents(0)));

      expect(snapshot.monthlySeries[3].label, equals('2026-06'));
      expect(snapshot.monthlySeries[3].expenseAmount, equals(Money.fromCents(20000)));

      expect(snapshot.isMonthlySeriesSumExact, isTrue);
    });

    test('Comparativo percentual evita divisão por zero e NaN', () {
      final percent1 = AnalysisCalculator.calculatePercentageChange(
        current: Money.fromCents(5000),
        previous: Money.fromCents(0),
      );
      expect(percent1, equals(100.0));

      final percent2 = AnalysisCalculator.calculatePercentageChange(
        current: Money.fromCents(0),
        previous: Money.fromCents(0),
      );
      expect(percent2, equals(0.0));

      final percent3 = AnalysisCalculator.calculatePercentageChange(
        current: Money.fromCents(15000),
        previous: Money.fromCents(10000),
      );
      expect(percent3, closeTo(50.0, 0.001));
    });
  });

  group('AnalysisViewModel - Reatividade e Preservação de Estado', () {
    test('Preserva selectedMonthForCategory após inserções ou notificações de despesas', () {
      final categoryVm = CategoryViewModel();
      final expenseVm = ExpenseViewModel();

      final analysisVm = AnalysisViewModel(
        categoryViewModel: categoryVm,
        expenseViewModel: expenseVm,
        clock: fixedClock,
      );

      final targetMonth = DateTime(2026, 5, 1);
      analysisVm.setSelectedMonthForCategory(targetMonth);
      expect(analysisVm.selectedMonthForCategory, equals(targetMonth));

      expenseVm.notifyListeners();

      expect(analysisVm.selectedMonthForCategory, equals(targetMonth));

      analysisVm.dispose();
    });

    test('Recalcula snapshot reativamente quando expenseViewModel notifica', () {
      final categoryVm = CategoryViewModel();
      final expenseVm = ExpenseViewModel();

      final analysisVm = AnalysisViewModel(
        categoryViewModel: categoryVm,
        expenseViewModel: expenseVm,
        clock: fixedClock,
      );

      expect(analysisVm.totalCurrentMonth, equals(0.0));

      expenseVm.allExpenses = [
        _createExpense(
          id: 'exp_reactive',
          motivation: 'Compra Nova',
          amount: 88.50,
          date: DateTime(2026, 6, 10),
        ),
      ];

      expect(analysisVm.totalCurrentMonth, equals(88.50));
      expect(analysisVm.currentSnapshot.totalExpenses, equals(Money.fromCents(8850)));

      analysisVm.dispose();
    });
  });

  group('CsvService & Snapshot - Exportação Determinística Congelada', () {
    test('exportAnalysisCsv com snapshot pré-calculado gera linhas consistentes', () {
      final csvService = CsvService();

      final query = AnalysisQuery.forMonth(DateTime(2026, 6, 1));

      final expenses = [
        _createExpense(
          id: 'e1',
          motivation: 'Supermercado',
          amount: 250.00,
          date: DateTime(2026, 6, 5),
          categoryId: 'cat_alim',
        ),
      ];

      final snapshot = AnalysisCalculator.calculate(
        query: query,
        expenses: expenses,
        categories: [catAlimentacao],
        capturedAt: fixedClock.now(),
      );

      final csvContent = csvService.generateAnalysisCsvContent(snapshot);

      expect(csvContent.contains('RELATÓRIO DE ANÁLISE FINANCEIRA - KEYBUDGET'), isTrue);
      expect(csvContent.contains('Total de Despesas'), isTrue);
      expect(csvContent.contains('250,00'), isTrue);
      expect(csvContent.contains('Alimentação'), isTrue);
      expect(csvContent.contains('100.0%'), isTrue);
    });
  });
}
