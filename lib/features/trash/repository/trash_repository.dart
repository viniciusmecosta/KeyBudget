import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/features/expenses/domain/recurrence_occurrence.dart';

class TrashEntry {
  final String id;
  final String collection;
  final String title;
  final DateTime deletedAt;
  final List<Map<String, dynamic>> records;

  const TrashEntry({
    required this.id,
    required this.collection,
    required this.title,
    required this.deletedAt,
    required this.records,
  });

  factory TrashEntry.fromMap(String id, Map<String, dynamic> map) {
    return TrashEntry(
      id: id,
      collection: map['collection'] as String,
      title: map['title'] as String,
      deletedAt: (map['deletedAt'] as Timestamp).toDate(),
      records: (map['records'] as List<dynamic>)
          .map((record) => Map<String, dynamic>.from(record as Map))
          .toList(),
    );
  }
}

class TrashRepository {
  static const supportedCollections = {
    'expenses',
    'credentials',
    'documents',
    'suppliers',
  };

  final FirebaseFirestore? _customFirestore;

  TrashRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _user(String userId) =>
      _firestore.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>> _trash(String userId) =>
      _user(userId).collection('trash');

  Stream<List<TrashEntry>> watch(String userId) => _trash(userId)
      .orderBy('deletedAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((document) => TrashEntry.fromMap(document.id, document.data()))
            .toList(),
      );

  Future<void> move(
    String userId, {
    required String collection,
    required List<String> ids,
    required String title,
  }) async {
    if (!supportedCollections.contains(collection) ||
        ids.isEmpty ||
        ids.length > 200 ||
        ids.toSet().length != ids.length) {
      throw ArgumentError('Itens inválidos para a lixeira.');
    }
    final source = _user(userId).collection(collection);
    final trashDocument = _trash(userId).doc();
    await _firestore.runTransaction((transaction) async {
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final id in ids) {
        snapshots.add(await transaction.get(source.doc(id)));
      }
      if (snapshots.any((snapshot) => !snapshot.exists)) {
        throw StateError('Um dos itens não existe mais. Atualize a lista.');
      }
      if (collection == 'expenses' &&
          snapshots.any((snapshot) {
            final recurringId = snapshot.data()?['recurringExpenseId'];
            return recurringId is String && recurringId.isNotEmpty;
          })) {
        throw StateError('Use a exclusão de ocorrência recorrente.');
      }
      final records = [
        for (final snapshot in snapshots)
          {'id': snapshot.id, 'data': snapshot.data()!},
      ];
      transaction.set(trashDocument, {
        'collection': collection,
        'title': title,
        'deletedAt': Timestamp.fromDate(DateTime.now()),
        'records': records,
      });
      for (final snapshot in snapshots) {
        transaction.delete(snapshot.reference);
      }
    });
  }

  Future<void> moveRecurringExpense(String userId, String expenseId) async {
    final source = _user(userId).collection('expenses').doc(expenseId);
    final trashDocument = _trash(userId).doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(source);
      if (!snapshot.exists) {
        throw StateError('O lançamento não existe mais. Atualize a lista.');
      }
      final expense = Expense.fromMap(snapshot.data()!, snapshot.id);
      final occurrence = RecurrenceOccurrence.forExpense(
        userId: userId,
        expense: expense,
        state: OccurrenceState.materialized,
      );
      if (occurrence == null) {
        throw StateError('Este lançamento não pertence a uma recorrência.');
      }
      final occurrenceDocument = _user(
        userId,
      ).collection('recurrence_occurrences').doc(occurrence.occurrenceKey);
      final currentOccurrence = await transaction.get(occurrenceDocument);
      final previous = currentOccurrence.exists
          ? RecurrenceOccurrence.fromMap(
              currentOccurrence.data()!,
              occurrence.occurrenceKey,
            )
          : null;
      final tombstone = (previous ?? occurrence).copyWith(
        expenseIds: {...?previous?.expenseIds, expenseId}.toList(),
        state: OccurrenceState.suppressed,
      );
      transaction.set(trashDocument, {
        'collection': 'expenses',
        'title': expense.motivation?.trim().isNotEmpty == true
            ? expense.motivation
            : 'Lançamento recorrente',
        'deletedAt': Timestamp.fromDate(DateTime.now()),
        'records': [
          {'id': expenseId, 'data': snapshot.data()!},
        ],
      });
      transaction.set(occurrenceDocument, tombstone.toMap());
      transaction.delete(source);
    });
  }

  Future<void> restore(String userId, String trashId) async {
    final trashDocument = _trash(userId).doc(trashId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(trashDocument);
      if (!snapshot.exists) throw StateError('Item não encontrado na lixeira.');
      final entry = TrashEntry.fromMap(trashId, snapshot.data()!);
      if (!supportedCollections.contains(entry.collection)) {
        throw StateError('Tipo de item não suportado.');
      }
      final source = _user(userId).collection(entry.collection);
      final targets = <DocumentSnapshot<Map<String, dynamic>>>[];
      final restoredIds = entry.records
          .map((record) => record['id'] as String)
          .toSet();
      for (final record in entry.records) {
        targets.add(await transaction.get(source.doc(record['id'] as String)));
      }
      if (entry.collection == 'documents') {
        final parentIds = <String>{};
        for (final record in entry.records) {
          final data = Map<String, dynamic>.from(record['data'] as Map);
          final parentId = data['originalDocumentId'];
          if (parentId is String &&
              parentId.isNotEmpty &&
              !restoredIds.contains(parentId)) {
            parentIds.add(parentId);
          }
        }
        for (final parentId in parentIds) {
          final parent = await transaction.get(source.doc(parentId));
          if (!parent.exists) {
            throw StateError('Restaure primeiro o documento principal.');
          }
        }
      }
      if (targets.any((target) => target.exists)) {
        throw StateError('Já existe um item com o mesmo identificador.');
      }
      final occurrencesToRestore =
          <DocumentReference<Map<String, dynamic>>, RecurrenceOccurrence>{};
      if (entry.collection == 'expenses') {
        for (final record in entry.records) {
          final id = record['id'] as String;
          final expense = Expense.fromMap(
            Map<String, dynamic>.from(record['data'] as Map),
            id,
          );
          final occurrence = RecurrenceOccurrence.forExpense(
            userId: userId,
            expense: expense,
            state: OccurrenceState.materialized,
          );
          if (occurrence == null) continue;
          final reference = _user(
            userId,
          ).collection('recurrence_occurrences').doc(occurrence.occurrenceKey);
          final current = await transaction.get(reference);
          if (current.exists) {
            final existing = RecurrenceOccurrence.fromMap(
              current.data()!,
              occurrence.occurrenceKey,
            );
            if (existing.state != OccurrenceState.suppressed ||
                !existing.expenseIds.contains(id)) {
              throw StateError(
                'A ocorrência já foi alterada. Atualize a lista.',
              );
            }
            for (final otherId in existing.expenseIds.where(
              (linkedId) => linkedId != id,
            )) {
              if (!(await transaction.get(source.doc(otherId))).exists) {
                throw StateError(
                  'Há outro lançamento pendente nesta recorrência.',
                );
              }
            }
            occurrencesToRestore[reference] = existing.copyWith(
              state: OccurrenceState.materialized,
            );
          } else {
            occurrencesToRestore[reference] = occurrence;
          }
        }
      }
      for (var index = 0; index < targets.length; index++) {
        final data = Map<String, dynamic>.from(
          entry.records[index]['data'] as Map,
        );
        if (entry.collection == 'expenses' && data['dateKey'] == null) {
          final date = Expense.fromMap(
            data,
            entry.records[index]['id'] as String,
          ).date;
          data['dateKey'] =
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
        transaction.set(targets[index].reference, data);
      }
      for (final occurrence in occurrencesToRestore.entries) {
        transaction.set(occurrence.key, occurrence.value.toMap());
      }
      transaction.delete(trashDocument);
    });
  }

  Future<void> deleteForever(String userId, String trashId) async {
    final trashDocument = _trash(userId).doc(trashId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(trashDocument);
      if (!snapshot.exists) return;
      final entry = TrashEntry.fromMap(trashId, snapshot.data()!);
      if (entry.collection == 'documents') {
        final driveIds = <String>{};
        for (final record in entry.records) {
          final data = Map<String, dynamic>.from(record['data'] as Map);
          for (final attachment
              in data['attachments'] as List<dynamic>? ?? []) {
            if (attachment is Map && attachment['driveId'] is String) {
              driveIds.add(attachment['driveId'] as String);
            }
          }
        }
        if (driveIds.isNotEmpty) {
          transaction.update(_user(userId), {
            'pendingDocumentAttachmentCleanup': FieldValue.arrayUnion(
              driveIds.toList(),
            ),
          });
        }
      }
      transaction.delete(trashDocument);
    });
  }
}

final trashRepositoryProvider = Provider<TrashRepository>(
  (ref) => TrashRepository(),
);

final trashEntriesProvider = StreamProvider.family<List<TrashEntry>, String>(
  (ref, userId) => ref.read(trashRepositoryProvider).watch(userId),
);
