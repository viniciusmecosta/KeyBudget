import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:passfin/core/models/user_model.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/features/category/viewmodel/category_viewmodel.dart';
import 'package:passfin/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:passfin/features/dashboard/repository/dashboard_layout_repository.dart';
import 'package:passfin/features/dashboard/view/dashboard_screen.dart';
import 'package:passfin/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:passfin/features/expenses/viewmodel/expense_viewmodel.dart';
import 'dashboard_test.dart'
    show
        FakeAuthVM,
        FakeCategoryVM,
        FakeExpenseVM,
        FakeCredentialVM,
        FakeDashboardVM;

class RefreshExpenses extends FakeExpenseVM {
  int retries = 0;
  @override
  Future<void> retryListenToExpenses(String userId) async {
    retries++;
  }
}

class RefreshCredentials extends FakeCredentialVM {
  int retries = 0;
  @override
  void retryListenToCredentials(String userId) {
    retries++;
  }
}

void main() {
  testWidgets('pull refresh renews both subscriptions and keeps the panel', (
    tester,
  ) async {
    await initializeDateFormatting('pt_BR');
    final expenses = RefreshExpenses();
    final credentials = RefreshCredentials();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(
            (ref) => FakeAuthVM(
              mockUser: User(id: 'u', name: 'Teste', email: 'test@example.com'),
            ),
          ),
          expenseViewModelProvider.overrideWith((ref) => expenses),
          credentialViewModelProvider.overrideWith((ref) => credentials),
          categoryViewModelProvider.overrideWith((ref) => FakeCategoryVM()),
          dashboardViewModelProvider.overrideWith((ref) => FakeDashboardVM()),
          dashboardLayoutProvider(
            'u',
          ).overrideWith((ref) => Stream.value(const DashboardLayout())),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    await tester.pumpAndSettle();
    expect(expenses.retries, 1);
    expect(credentials.retries, 1);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('Personalizar painel'), findsNothing);
    expect(find.text('Painel'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
