import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/repository/dashboard_layout_repository.dart';
import 'package:key_budget/features/dashboard/view/dashboard_screen.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/goals/model/savings_goal.dart';
import 'package:key_budget/features/goals/repository/savings_goal_repository.dart';
import 'package:key_budget/features/goals/view/savings_goals_screen.dart';

import '../features/dashboard/dashboard_test.dart' as fakes;

class _Goals extends SavingsGoalRepository {
  @override
  Future<void> resumePendingDeletions(String userId) async {}
  @override
  Stream<List<SavingsGoal>> watchGoals(String userId) => Stream.value([
    SavingsGoal(
      id: '1',
      name: 'Reserva de emergência',
      targetMinor: 1200000,
      savedMinor: 480000,
      createdAt: DateTime(2026, 10, 1),
    ),
    SavingsGoal(
      id: '2',
      name: 'Próxima viagem',
      targetMinor: 600000,
      savedMinor: 150000,
      createdAt: DateTime(2026, 10, 1),
    ),
  ]);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    // Bundled fallback keeps captures independent of network font downloads.
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
  });
  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0, 1024.0]) {
      for (final goals in [false, true]) {
        testWidgets(
          '${goals ? "goals" : "dashboard"} ${dark ? "dark" : "light"} $width',
          (tester) async {
            final semantics = tester.ensureSemantics();
            tester.view.physicalSize = Size(width, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final key = GlobalKey();
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  authViewModelProvider.overrideWith(
                    (ref) => fakes.FakeAuthVM(
                      mockUser: User(
                        id: 'user',
                        name: 'Marina',
                        email: 'demo@example.com',
                        enableIncomes: width == 320,
                      ),
                    ),
                  ),
                  categoryViewModelProvider.overrideWith(
                    (ref) => fakes.FakeCategoryVM(),
                  ),
                  expenseViewModelProvider.overrideWith(
                    (ref) => fakes.FakeExpenseVM(),
                  ),
                  credentialViewModelProvider.overrideWith(
                    (ref) => fakes.FakeCredentialVM(),
                  ),
                  dashboardViewModelProvider.overrideWith(
                    (ref) => fakes.FakeDashboardVM(),
                  ),
                  dashboardLayoutProvider('user').overrideWith(
                    (ref) => Stream.value(const DashboardLayout()),
                  ),
                  savingsGoalRepositoryProvider.overrideWithValue(_Goals()),
                ],
                child: MaterialApp(
                  theme: AppTheme.getTheme(isDark: dark),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(width == 320 ? 1.8 : 1),
                    ),
                    child: child!,
                  ),
                  home: RepaintBoundary(
                    key: key,
                    child: goals
                        ? const SavingsGoalsScreen()
                        : const DashboardScreen(),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (!goals) {
              final action = tester.getRect(
                find.byTooltip('Abrir análise financeira'),
              );
              final heading = tester.getRect(
                find.text(
                  width == 320 ? 'Entradas vs Saídas' : 'Gastos realizados',
                ),
              );
              expect(action.width, greaterThanOrEqualTo(48));
              expect(action.height, greaterThanOrEqualTo(48));
              expect(action.top, lessThan(heading.bottom));
              expect(action.bottom, greaterThan(heading.top));
              final summary = find.bySemanticsLabel(
                RegExp(r'^Ver lançamentos\.'),
              );
              expect(
                tester
                    .getSemantics(summary)
                    .getSemanticsData()
                    .hasAction(ui.SemanticsAction.tap),
                isTrue,
              );
            }
            if (goals) {
              final fab = find.byType(FloatingActionButton);
              expect(tester.getRect(fab).right, lessThanOrEqualTo(width));
              await tester.tap(fab);
              await tester.pumpAndSettle();
              expect(find.text('Salvar'), findsOneWidget);
              expect(tester.takeException(), isNull);
              await tester.tap(find.text('Cancelar'));
              await tester.pumpAndSettle();
            }
            if (Platform.environment['CAPTURE_UI'] == '1') {
              await tester.runAsync(() async {
                final boundary =
                    key.currentContext!.findRenderObject()
                        as RenderRepaintBoundary;
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                File(
                  '/tmp/keybudget-${goals ? "goals" : "dashboard"}-${dark ? "dark" : "light"}-${width.toInt()}.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            semantics.dispose();
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
          },
        );
      }
    }
  }
}
