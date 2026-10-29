import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/core/models/user_model.dart';
import 'package:passfin/features/auth/repository/auth_repository.dart';
import 'package:passfin/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:passfin/features/dashboard/repository/dashboard_layout_repository.dart';
import 'package:passfin/features/dashboard/widgets/dashboard_layout_editor.dart';

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
    expect(layout.integratedSummary, isTrue);
    expect(
      DashboardLayout.fromMap(
        const DashboardLayout(integratedSummary: false).toMap(),
      ).integratedSummary,
      isFalse,
    );
    expect(layout.actions, DashboardLayout.actionIds);
  });

  test(
    'optional category chart survives persistence without changing defaults',
    () {
      final layout = DashboardLayout.fromMap({
        'cards': ['categories', 'recent'],
      });
      expect(DashboardLayout.fromMap(layout.toMap()).cards, [
        'categories',
        'recent',
      ]);
      expect(const DashboardLayout().cards, isNot(contains('categories')));
    },
  );

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
          authViewModelProvider.overrideWith(
            (ref) => _AuthWithSuppliers(false),
          ),
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
    await tester.tap(find.byKey(const ValueKey('size_chart')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compacto').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gastos mensais'));
    await tester.pump();
    await tester.tap(find.text('Salvar painel'));
    await tester.pumpAndSettle();
    expect(repository.saved?.cards, ['balance', 'quick_actions', 'recent']);
    expect(repository.saved?.sizeFor('chart'), DashboardCardSize.compact);
  });

  testWidgets('size controls remain usable at 320px and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _SavingLayoutRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(
            (ref) => _AuthWithSuppliers(false),
          ),
          dashboardLayoutRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: DashboardLayoutEditor(
              userId: 'user',
              initial: DashboardLayout(cards: ['daily', 'recent']),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('size_daily')));
    await tester.tap(find.byKey(const ValueKey('size_daily')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Amplo').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Salvar painel'));
    await tester.pump();
    expect(repository.saved?.sizeFor('daily'), DashboardCardSize.large);
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
