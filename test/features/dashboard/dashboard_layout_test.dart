import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/features/dashboard/repository/dashboard_layout_repository.dart';
import 'package:key_budget/features/dashboard/widgets/dashboard_layout_editor.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/core/models/user_model.dart';

class _FakeAuthRepository extends Fake implements AuthRepository {}

class _AuthWithSuppliers extends AuthViewModel {
  _AuthWithSuppliers(bool enabled)
    : _enabled = enabled,
      super(authRepository: _FakeAuthRepository(), listenToAuthChanges: false);

  final bool _enabled;

  @override
  User? get currentUser => User(
    id: 'user',
    name: 'Teste',
    email: 'teste@example.com',
    enableSuppliers: _enabled,
  );
}

class _SavingLayoutRepository extends DashboardLayoutRepository {
  DashboardLayout? saved;

  @override
  Future<void> save(String userId, DashboardLayout layout) async {
    expect(userId, 'user');
    saved = layout;
  }
}

void main() {
  test('legacy profile uses the complete default panel', () {
    final layout = DashboardLayout.fromMap(null);
    expect(layout.cards, DashboardLayout.cardIds);
    expect(layout.actions, DashboardLayout.actionIds);
  });

  test('saved order is kept while invalid ids and duplicates are removed', () {
    final layout = DashboardLayout.fromMap({
      'cards': ['chart', 'chart', 'unknown', 'balance'],
      'actions': ['analysis', 'expense', 'analysis', 'unknown'],
    });
    expect(layout.cards, ['chart', 'balance', 'recent']);
    expect(layout.actions, ['analysis', 'expense']);
    expect(DashboardLayout.fromMap(layout.toMap()).cards, layout.cards);
  });

  testWidgets('editor hides optional cards but preserves recent activities', (
    tester,
  ) async {
    final repository = _SavingLayoutRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith((ref) => _AuthWithSuppliers(false)),
          dashboardLayoutRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const DashboardLayoutEditor(
                    userId: 'user',
                    initial: DashboardLayout(),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.ancestor(
              of: find.text('Atividades recentes'),
              matching: find.byType(CheckboxListTile),
            ),
          )
          .onChanged,
      isNull,
    );
    await tester.tap(find.text('Gastos mensais'));
    await tester.pump();
    await tester.tap(find.text('Salvar painel'));
    await tester.pumpAndSettle();
    expect(repository.saved?.cards, ['balance', 'quick_actions', 'recent']);
  });

  for (final enabled in [false, true]) {
    testWidgets('supplier shortcut follows module setting: $enabled', (
      tester,
    ) async {
      final repository = _SavingLayoutRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authViewModelProvider.overrideWith(
              (ref) => _AuthWithSuppliers(enabled),
            ),
            dashboardLayoutRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DashboardLayoutEditor(
                userId: 'user',
                initial: DashboardLayout(),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('Fornecedores'),
        enabled ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Salvar painel'));
      await tester.pump();
      expect(repository.saved?.actions, contains('suppliers'));
    });
  }
}
