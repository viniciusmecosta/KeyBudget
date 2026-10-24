import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/analysis/widgets/analysis_stats_overview_widget.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

import 'analysis_presentation_test.dart'
    show FakeAuthVM, FakeCategoryVM, FakeExpenseVM;

void main() {
  for (final width in [320.0, 390.0, 800.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final incomes in [false, true]) {
        testWidgets('analysis width=$width scale=$scale incomes=$incomes', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final expenses = FakeExpenseVM(
            initialExpenses: [
              Expense(
                id: 'large',
                amount: 9876543.21,
                date: DateTime.now(),
                categoryId: 'category',
                location: 'Compra',
              ),
            ],
          );
          final categories = FakeCategoryVM([]);
          addTearDown(expenses.dispose);
          addTearDown(categories.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                analysisViewModelProvider.overrideWith(
                  (ref) => AnalysisViewModel(
                    categoryViewModel: categories,
                    expenseViewModel: expenses,
                  ),
                ),
                authViewModelProvider.overrideWith(
                  (ref) => FakeAuthVM(
                    mockUser: User(
                      id: 'user',
                      name: 'Pessoa',
                      email: 'teste@example.com',
                      enableIncomes: incomes,
                    ),
                  ),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.getTheme(isDark: incomes),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const Scaffold(
                  body: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: AnalysisStatsOverviewWidget(),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(FittedBox), findsNothing);
          expect(find.textContaining('9.876.543,21'), findsWidgets);
          final cards = find.byType(AppCard);
          final first = incomes ? 1 : 0;
          final firstRect = tester.getRect(cards.at(first));
          final secondRect = tester.getRect(cards.at(first + 1));
          if (width - 32 >= 320 * scale + 16) {
            expect(firstRect.top, secondRect.top);
          } else {
            expect(secondRect.top, greaterThan(firstRect.bottom));
          }
        });
      }
    }
  }
}
