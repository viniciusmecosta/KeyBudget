import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passfin/features/goals/model/savings_goal.dart';

void main() {
  test('A meta preserva valores, prazo e estado ao serializar', () {
    final createdAt = DateTime(2026, 10, 1);
    final deadline = DateTime(2027, 1, 1);
    final goal = SavingsGoal(
      id: 'goal-1',
      name: 'Reserva',
      targetMinor: 50000,
      savedMinor: 12500,
      createdAt: createdAt,
      deadline: deadline,
      isArchived: true,
      isDeleting: true,
    );

    final restored = SavingsGoal.fromMap(goal.id, goal.toMap());

    expect(restored.name, 'Reserva');
    expect(restored.targetMinor, 50000);
    expect(restored.savedMinor, 12500);
    expect(restored.remainingMinor, 37500);
    expect(restored.progress, 0.25);
    expect(restored.deadline, deadline);
    expect(restored.isArchived, isTrue);
    expect(restored.isDeleting, isTrue);
    expect(restored.toMap()['createdAt'], isA<Timestamp>());
  });

  test('Meta rejeita saldos inválidos e dados incompletos', () {
    final base = {
      'name': 'Reserva',
      'targetMinor': 10000,
      'savedMinor': 0,
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
    };

    expect(
      () => SavingsGoal.fromMap('goal-1', {...base, 'savedMinor': -1}),
      throwsFormatException,
    );
    expect(
      () => SavingsGoal.fromMap('goal-1', {...base, 'targetMinor': 0}),
      throwsFormatException,
    );
    expect(
      () => SavingsGoal.fromMap('goal-1', {...base, 'name': ' '}),
      throwsFormatException,
    );
  });
}
