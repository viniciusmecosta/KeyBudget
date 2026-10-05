import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/models/expense_model.dart';

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
