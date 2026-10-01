import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/expenses/widgets/expense_sync_indicator.dart';

void main() {
  testWidgets('hides the normal state and short-lived cache snapshots', (
    tester,
  ) async {
    var retries = 0;

    Future<void> show(ExpenseSyncStatus status) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSyncIndicator(
              status: status,
              onRetry: () => retries++,
            ),
          ),
        ),
      );
    }

    await show(ExpenseSyncStatus.synced);
    expect(find.text('Sincronizado'), findsNothing);

    await show(ExpenseSyncStatus.cached);
    expect(find.text('Em cache'), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    await show(ExpenseSyncStatus.synced);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Em cache'), findsNothing);

    await show(ExpenseSyncStatus.cached);
    await tester.pump(const Duration(milliseconds: 801));
    expect(find.text('Em cache'), findsOneWidget);
    await tester.tap(find.byTooltip('Tentar sincronizar novamente'));
    expect(retries, 1);

    await show(ExpenseSyncStatus.synced);
    expect(find.text('Em cache'), findsNothing);
  });

  testWidgets('keeps pending and failed states compact and actionable', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseSyncIndicator(
            status: ExpenseSyncStatus.pending,
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.text('Pendente'), findsOneWidget);
    expect(find.byTooltip('Tentar sincronizar novamente'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseSyncIndicator(
            status: ExpenseSyncStatus.failed,
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(find.text('Falha'), findsOneWidget);
    await tester.tap(find.byTooltip('Tentar sincronizar novamente'));
    expect(retries, 1);
  });
}
