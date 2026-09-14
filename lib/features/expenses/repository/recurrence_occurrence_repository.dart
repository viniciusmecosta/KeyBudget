import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/features/expenses/domain/recurrence_occurrence.dart';

class RecurrenceOccurrenceRepository {
  final FirebaseFirestore? _customFirestore;

  RecurrenceOccurrenceRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<RecurrenceOccurrence> _getCollection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recurrence_occurrences')
        .withConverter<RecurrenceOccurrence>(
          fromFirestore: (snapshot, _) =>
              RecurrenceOccurrence.fromMap(snapshot.data()!, snapshot.id),
          toFirestore: (occurrence, _) => occurrence.toMap(),
        );
  }

  Future<RecurrenceOccurrence?> getOccurrence(
    String userId,
    String occurrenceKey,
  ) async {
    final doc = await _getCollection(userId).doc(occurrenceKey).get();
    return doc.data();
  }

  Future<List<RecurrenceOccurrence>> getOccurrencesForRule(
    String userId,
    String ruleId,
  ) async {
    final query = await _getCollection(userId)
        .where('recurringExpenseId', isEqualTo: ruleId)
        .get();
    return query.docs.map((d) => d.data()).toList();
  }

  Future<List<RecurrenceOccurrence>> getAllOccurrences(String userId) async {
    final query = await _getCollection(userId).get();
    return query.docs.map((d) => d.data()).toList();
  }

  Future<void> saveOccurrence(
    String userId,
    RecurrenceOccurrence occurrence,
  ) async {
    await _getCollection(userId)
        .doc(occurrence.occurrenceKey)
        .set(occurrence);
  }

  Future<void> saveOccurrencesBatch(
    String userId,
    List<RecurrenceOccurrence> occurrences,
  ) async {
    final batch = _firestore.batch();
    final collection = _getCollection(userId);
    for (final occ in occurrences) {
      batch.set(collection.doc(occ.occurrenceKey), occ);
    }
    await batch.commit();
  }

  Future<void> deleteOccurrence(String userId, String occurrenceKey) async {
    await _getCollection(userId).doc(occurrenceKey).delete();
  }
}

final recurrenceOccurrenceRepositoryProvider =
    Provider<RecurrenceOccurrenceRepository>(
  (ref) => RecurrenceOccurrenceRepository(),
);
