import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/goals/model/savings_goal.dart';
import 'package:key_budget/features/goals/repository/savings_goal_repository.dart';
import 'package:key_budget/features/goals/view/savings_goals_screen.dart';

class _AuthViewModel extends AuthViewModel {
  _AuthViewModel() : super(listenToAuthChanges: false);

  @override
  User? get currentUser =>
      User(id: 'user', name: 'Teste', email: 'teste@example.com');
}

class _GoalRepository extends SavingsGoalRepository {
  _GoalRepository(this.goal);

  final SavingsGoal goal;
  int deletions = 0;

  @override
  Stream<List<SavingsGoal>> watchGoals(String userId) => Stream.value([goal]);

  @override
  Future<void> resumePendingDeletions(String userId) async {}

  @override
  Future<void> deleteGoal(String userId, String goalId) async {
    expect(userId, 'user');
    expect(goalId, goal.id);
    deletions++;
  }
}

void main() {
  for (final archived in [false, true]) {
    testWidgets(
      archived
          ? 'archived goals can be permanently deleted with confirmation'
          : 'active goals can be permanently deleted with confirmation',
      (tester) async {
        final repository = _GoalRepository(
          SavingsGoal(
            id: 'goal',
            name: 'Reserva',
            targetMinor: 10000,
            savedMinor: 5000,
            createdAt: DateTime(2026, 10, 1),
            isArchived: archived,
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              savingsGoalRepositoryProvider.overrideWithValue(repository),
              authViewModelProvider.overrideWith((ref) => _AuthViewModel()),
            ],
            child: const MaterialApp(home: SavingsGoalsScreen()),
          ),
        );
        await tester.pumpAndSettle();
        if (archived) {
          await tester.tap(find.byTooltip('Ver metas arquivadas'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byTooltip('Opções da meta Reserva'));
        await tester.pumpAndSettle();
        expect(find.text('Excluir tudo'), findsOneWidget);
        await tester.tap(find.text('Excluir tudo'));
        await tester.pumpAndSettle();
        expect(repository.deletions, 0);
        await tester.tap(find.text('Cancelar'));
        await tester.pumpAndSettle();
        expect(repository.deletions, 0);

        await tester.tap(find.byTooltip('Opções da meta Reserva'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir tudo'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Excluir tudo'));
        await tester.pumpAndSettle();
        expect(repository.deletions, 1);
        await tester.pump(const Duration(seconds: 4));
      },
    );
  }

  testWidgets('a pending deletion can be resumed without a second prompt', (
    tester,
  ) async {
    final repository = _GoalRepository(
      SavingsGoal(
        id: 'goal',
        name: 'Reserva',
        targetMinor: 10000,
        savedMinor: 5000,
        createdAt: DateTime(2026, 10, 1),
        isDeleting: true,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savingsGoalRepositoryProvider.overrideWithValue(repository),
          authViewModelProvider.overrideWith((ref) => _AuthViewModel()),
        ],
        child: const MaterialApp(home: SavingsGoalsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Exclusão pendente. Use o menu para concluir.'),
      findsOneWidget,
    );
    expect(find.text('Adicionar'), findsNothing);
    await tester.tap(find.byTooltip('Opções da meta Reserva'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluir exclusão'));
    await tester.pumpAndSettle();
    expect(repository.deletions, 1);
    expect(find.text('Excluir meta e histórico?'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });
}
