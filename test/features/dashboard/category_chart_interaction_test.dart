import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/models/expense_model.dart';
import 'package:passfin/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:passfin/features/dashboard/widgets/dashboard_category_summary.dart';
import 'dashboard_test.dart' show FakeDashboardVM;

void main() {
  testWidgets('tapping a donut segment reveals its value', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardViewModelProvider.overrideWith(
            (ref) => FakeDashboardVM(
              testExpenses: [Expense(amount: 123.45, date: DateTime.now())],
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DashboardCategorySummary()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('123,45'), findsNothing);
    await tester.tapAt(
      tester.getCenter(find.byType(PieChart)) + const Offset(55, 0),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('123,45'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
