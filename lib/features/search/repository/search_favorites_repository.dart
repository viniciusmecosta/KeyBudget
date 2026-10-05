import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchFavoritesRepository {
  final FirebaseFirestore? _customFirestore;

  SearchFavoritesRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('search_favorites');

  Stream<Set<String>> watch(String userId) => _collection(userId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((document) => document.id).toSet());

  Future<void> setFavorite(String userId, String id, bool favorite) async {
    final document = _collection(userId).doc(id);
    if (favorite) {
      await document.set({'savedAt': Timestamp.fromDate(DateTime.now())});
    } else {
      await document.delete();
    }
  }
}

final searchFavoritesRepositoryProvider = Provider<SearchFavoritesRepository>(
  (ref) => SearchFavoritesRepository(),
);

final searchFavoritesProvider = StreamProvider.family<Set<String>, String>(
  (ref, userId) => ref.read(searchFavoritesRepositoryProvider).watch(userId),
);
