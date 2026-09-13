import 'package:cloud_firestore/cloud_firestore.dart';

abstract class RawStorageReader {
  Future<Map<String, dynamic>?> getDocument(String path);
  Future<List<Map<String, dynamic>>> getCollection(String path);
}

abstract class RawStorageWriter {
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  });
  Future<void> deleteDocument(String path);
}

class FirestoreRawStorage implements RawStorageReader, RawStorageWriter {
  final FirebaseFirestore _firestore;

  FirestoreRawStorage({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Map<String, dynamic>?> getDocument(String path) async {
    final docRef = _firestore.doc(path);

    final snapshot = await docRef.get(const GetOptions(source: Source.server));
    if (!snapshot.exists || snapshot.data() == null) return null;
    final map = Map<String, dynamic>.from(snapshot.data()!);
    map['id'] = snapshot.id;
    return map;
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String path) async {
    final colRef = _firestore.collection(path);
    final querySnapshot =
        await colRef.get(const GetOptions(source: Source.server));
    return querySnapshot.docs.map((doc) {
      final map = Map<String, dynamic>.from(doc.data());
      map['id'] = doc.id;
      return map;
    }).toList();
  }

  @override
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    final docRef = _firestore.doc(path);

    final cleanData = Map<String, dynamic>.from(data)..remove('id');
    await docRef.set(cleanData, SetOptions(merge: merge));
  }

  @override
  Future<void> deleteDocument(String path) async {
    await _firestore.doc(path).delete();
  }
}

class MemoryRawStorage implements RawStorageReader, RawStorageWriter {
  final Map<String, Map<String, dynamic>> documents = {};

  @override
  Future<Map<String, dynamic>?> getDocument(String path) async {
    final doc = documents[path];
    if (doc == null) return null;
    return Map<String, dynamic>.from(doc);
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String path) async {
    final prefix = path.endsWith('/') ? path : '$path/';
    final results = <Map<String, dynamic>>[];
    for (final entry in documents.entries) {
      if (entry.key.startsWith(prefix)) {
        final subPath = entry.key.substring(prefix.length);
        if (!subPath.contains('/')) {
          final doc = Map<String, dynamic>.from(entry.value);
          doc['id'] = subPath;
          results.add(doc);
        }
      }
    }
    return results;
  }

  @override
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    final cleanData = Map<String, dynamic>.from(data)..remove('id');
    final id = path.split('/').last;
    cleanData['id'] = id;
    if (merge && documents.containsKey(path)) {
      final existing = Map<String, dynamic>.from(documents[path]!);
      existing.addAll(cleanData);
      documents[path] = existing;
    } else {
      documents[path] = cleanData;
    }
  }

  @override
  Future<void> deleteDocument(String path) async {
    documents.remove(path);
  }
}
