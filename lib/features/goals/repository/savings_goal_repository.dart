import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/features/goals/model/savings_goal.dart';

class GoalMovement {
  final String id;
  final int amountMinor;
  final DateTime createdAt;

  const GoalMovement({
    required this.id,
    required this.amountMinor,
    required this.createdAt,
  });

  factory GoalMovement.fromMap(String id, Map<String, dynamic> data) =>
      GoalMovement(
        id: id,
        amountMinor: data['amountMinor'] as int,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
}

class SavingsGoalRepository {
  final FirebaseFirestore? _customFirestore;

  SavingsGoalRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('goals');

  CollectionReference<Map<String, dynamic>> _movements(String userId) =>
      _firestore.collection('users').doc(userId).collection('goal_movements');

  Stream<List<SavingsGoal>> watchGoals(String userId) => _collection(userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (document) => SavingsGoal.fromMap(document.id, document.data()),
            )
            .toList(),
      );

  Stream<List<GoalMovement>> watchMovements(String userId, String goalId) =>
      _movements(userId).where('goalId', isEqualTo: goalId).snapshots().map((
        snapshot,
      ) {
        final movements = snapshot.docs
            .map(
              (document) => GoalMovement.fromMap(document.id, document.data()),
            )
            .toList();
        movements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return movements;
      });

  Future<void> createGoal(
    String userId, {
    required String name,
    required int targetMinor,
    DateTime? deadline,
  }) async {
    if (name.trim().isEmpty || targetMinor <= 0) {
      throw ArgumentError('Informe nome e valor válidos para a meta.');
    }
    final document = _collection(userId).doc();
    await document.set(
      SavingsGoal(
        id: document.id,
        name: name.trim(),
        targetMinor: targetMinor,
        savedMinor: 0,
        createdAt: DateTime.now(),
        deadline: deadline,
      ).toMap(),
    );
  }

  Future<void> updateGoal(
    String userId,
    String goalId, {
    required String name,
    required int targetMinor,
    DateTime? deadline,
  }) async {
    if (name.trim().isEmpty || targetMinor <= 0) {
      throw ArgumentError('Informe nome e valor válidos para a meta.');
    }
    await _collection(userId).doc(goalId).update({
      'name': name.trim(),
      'targetMinor': targetMinor,
      'deadline': deadline == null ? null : Timestamp.fromDate(deadline),
    });
  }

  Future<void> moveAmount(String userId, String goalId, int amountMinor) async {
    if (amountMinor == 0) {
      throw ArgumentError('Informe um valor diferente de zero.');
    }
    final goalDocument = _collection(userId).doc(goalId);
    final movementDocument = _movements(userId).doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(goalDocument);
      if (!snapshot.exists) {
        throw StateError('Meta não encontrada.');
      }
      final goal = SavingsGoal.fromMap(goalId, snapshot.data()!);
      if (goal.isArchived) {
        throw StateError('A meta está arquivada.');
      }
      final newSaved = goal.savedMinor + amountMinor;
      if (newSaved < 0) {
        throw StateError('O saldo da meta não pode ficar negativo.');
      }
      transaction.update(goalDocument, {'savedMinor': newSaved});
      transaction.set(movementDocument, {
        'goalId': goalId,
        'amountMinor': amountMinor,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  Future<void> setArchived(String userId, String goalId, bool archived) =>
      _collection(userId).doc(goalId).update({'archived': archived});
}

final savingsGoalRepositoryProvider = Provider<SavingsGoalRepository>(
  (ref) => SavingsGoalRepository(),
);

final savingsGoalsProvider = StreamProvider.family<List<SavingsGoal>, String>(
  (ref, userId) => ref.read(savingsGoalRepositoryProvider).watchGoals(userId),
);

final goalMovementsProvider =
    StreamProvider.family<List<GoalMovement>, ({String userId, String goalId})>(
      (ref, scope) => ref
          .read(savingsGoalRepositoryProvider)
          .watchMovements(scope.userId, scope.goalId),
    );
