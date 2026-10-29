import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/app/config/app_theme.dart';
import 'package:passfin/core/models/expense_model.dart';
import 'package:passfin/features/dashboard/domain/dashboard_insights.dart';
import 'package:passfin/features/dashboard/widgets/dashboard_insight_chart.dart';

void main() {
  testWidgets('daily chart shows a single day without an invalid axis', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardInsightsProvider.overrideWithValue(
            DashboardInsights.fromExpenses([
              Expense(amount: 10, date: DateTime(2026, 10, 1)),
            ], DateTime(2026, 10, 1)),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: DashboardInsightChart(
              insight: DashboardInsight.daily,
              chartHeight: 104,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Dia 1'), findsOneWidget);
  });

  for (final insight in DashboardInsight.values) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$insight dark=$dark text=$scale at 320px', (tester) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final data = DashboardInsights.fromExpenses([
            Expense(amount: 12.34, date: DateTime(2026, 10, 1)),
            Expense(amount: 25, date: DateTime(2026, 10, 8)),
            Expense(amount: 30, date: DateTime(2026, 10, 16)),
          ], DateTime(2026, 10, 15));
          await tester.pumpWidget(
            ProviderScope(
              overrides: [dashboardInsightsProvider.overrideWithValue(data)],
              child: MaterialApp(
                theme: AppTheme.getTheme(isDark: dark),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: DashboardInsightChart(
                      insight: insight,
                      chartHeight: scale == 2 ? 104 : 208,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(IconButton));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
