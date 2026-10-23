import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/navigation/app_destination.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/main_bottom_navigation_bar.dart';
import 'package:key_budget/features/analysis/view/analysis_screen.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/view/credentials_screen.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/repository/dashboard_layout_repository.dart';
import 'package:key_budget/features/dashboard/view/dashboard_screen.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/documents/view/documents_screen.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:key_budget/features/expenses/view/expenses_screen.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:key_budget/features/goals/model/savings_goal.dart';
import 'package:key_budget/features/goals/repository/savings_goal_repository.dart';
import 'package:key_budget/features/goals/view/savings_goals_screen.dart';
import 'package:key_budget/features/user/view/user_screen.dart';

import 'demo_data.dart';

class _Goals extends SavingsGoalRepository {
  @override
  Future<void> resumePendingDeletions(String userId) async {}

  @override
  Stream<List<SavingsGoal>> watchGoals(String userId) => Stream.value([
    SavingsGoal(
      id: 'reserve',
      name: 'Reserva de emergência',
      targetMinor: 1200000,
      savedMinor: 480000,
      createdAt: DateTime(2026, 10, 1),
    ),
    SavingsGoal(
      id: 'travel',
      name: 'Próxima viagem',
      targetMinor: 600000,
      savedMinor: 150000,
      createdAt: DateTime(2026, 10, 1),
    ),
  ]);
}

void main() {
  setUpAll(() async {
    dotenv.loadFromString(
      envString: 'ENCRYPTION_KEY=12345678901234567890123456789012',
    );
    await initializeDateFormatting('pt_BR');
    final inter = FontLoader('Inter');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      inter.addFont(rootBundle.load('assets/fonts/Inter-$weight.ttf'));
    }
    await inter.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final screens = <String, (Widget, AppDestination)>{
    'home': (const DashboardScreen(), AppDestination.dashboard),
    'home-expenses': (const DashboardScreen(), AppDestination.dashboard),
    'dashboard-charts': (const DashboardScreen(), AppDestination.dashboard),
    'customization': (const UserScreen(), AppDestination.profile),
    'expenses': (const ExpensesScreen(), AppDestination.expenses),
    'credentials': (const CredentialsScreen(), AppDestination.credentials),
    'documents': (const DocumentsScreen(), AppDestination.documents),
    'analysis': (const AnalysisScreen(), AppDestination.dashboard),
    'analysis-distribution': (const AnalysisScreen(), AppDestination.dashboard),
    'goals': (const SavingsGoalsScreen(), AppDestination.profile),
    'profile': (const UserScreen(), AppDestination.profile),
  };
  for (final dark in [false, true]) {
    for (final entry in screens.entries) {
      testWidgets('README ${entry.key} ${dark ? "dark" : "light"}', (
        tester,
      ) async {
        final originalShadows = debugDisableShadows;
        debugDisableShadows = false;
        try {
          tester.view.physicalSize = const Size(412, 915);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final boundaryKey = GlobalKey();
          final category = FakeCategoryVM(HelperData.categories);
          final expenses = FakeExpenseVM(
            initialExpenses: HelperData.allExpensesList,
          );
          final credentials = FakeCredentialVM(
            mockFolders: HelperData.mockFolders,
            mockCredentials: HelperData.credentials,
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authViewModelProvider.overrideWith(
                  (ref) => FakeAuthVM(
                    mockUser: HelperData.mockUser.copyWith(
                      enableIncomes: entry.key != 'home-expenses',
                    ),
                  ),
                ),
                categoryViewModelProvider.overrideWith((ref) => category),
                expenseViewModelProvider.overrideWith((ref) => expenses),
                credentialViewModelProvider.overrideWith((ref) => credentials),
                documentViewModelProvider.overrideWith(
                  (ref) => FakeDocumentVM(mockDocuments: HelperData.documents),
                ),
                dashboardViewModelProvider.overrideWith(
                  (ref) => DashboardViewModel(
                    categoryViewModel: category,
                    expenseViewModel: expenses,
                    credentialViewModel: credentials,
                  ),
                ),
                analysisViewModelProvider.overrideWith(
                  (ref) => AnalysisViewModel(
                    categoryViewModel: category,
                    expenseViewModel: expenses,
                  ),
                ),
                navigationViewModelProvider.overrideWith(
                  (ref) => NavigationViewModel()..navigateTo(entry.value.$2),
                ),
                dashboardLayoutProvider('demo_user').overrideWith(
                  (ref) => Stream.value(
                    entry.key == 'dashboard-charts'
                        ? const DashboardLayout(
                            cards: [
                              'balance',
                              'categories',
                              'accumulated',
                              'recent',
                            ],
                          )
                        : const DashboardLayout(),
                  ),
                ),
                savingsGoalRepositoryProvider.overrideWithValue(_Goals()),
              ],
              child: RepaintBoundary(
                key: boundaryKey,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.getTheme(isDark: dark),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(disableAnimations: true),
                    child: child!,
                  ),
                  home: Scaffold(
                    extendBody: true,
                    body: entry.value.$1,
                    bottomNavigationBar:
                        [
                          'home',
                          'home-expenses',
                          'dashboard-charts',
                          'customization',
                          'expenses',
                          'credentials',
                          'documents',
                          'profile',
                        ].contains(entry.key)
                        ? const MainBottomNavigationBar()
                        : null,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (entry.key == 'dashboard-charts') {
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -260),
            );
            await tester.pumpAndSettle();
          }
          if (entry.key == 'analysis-distribution') {
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, -420),
            );
            await tester.pumpAndSettle();
          }
          if (entry.key == 'customization') {
            await tester.scrollUntilVisible(
              find.text('Personalizar painel'),
              240,
            );
            await tester.tap(find.text('Personalizar painel'));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          if (Platform.environment['CAPTURE_README'] == '1') {
            await tester.runAsync(() async {
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final folder = Directory(
                Platform.environment['SCREENSHOT_DIR'] ??
                    'build/readme-captures',
              )..createSync(recursive: true);
              File(
                '${folder.path}/${entry.key}-${dark ? "dark" : "light"}.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        } finally {
          debugDisableShadows = originalShadows;
        }
      });
    }
  }
}
