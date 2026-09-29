import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardLayout {
  static const cardIds = ['balance', 'chart', 'quick_actions', 'recent'];
  static const actionIds = ['expense', 'credentials', 'analysis', 'suppliers'];

  final List<String> cards;
  final List<String> actions;

  const DashboardLayout({this.cards = cardIds, this.actions = actionIds});

  factory DashboardLayout.fromMap(Object? raw) {
    if (raw is! Map) return const DashboardLayout();
    List<String> read(String key, List<String> allowed) {
      final value = raw[key];
      if (value is! List) return List.of(allowed);
      final selected = <String>[];
      for (final item in value) {
        if (item is String &&
            allowed.contains(item) &&
            !selected.contains(item)) {
          selected.add(item);
        }
      }
      return selected;
    }

    final cards = read('cards', cardIds);
    if (!cards.contains('recent')) cards.add('recent');
    return DashboardLayout(cards: cards, actions: read('actions', actionIds));
  }

  Map<String, dynamic> toMap() => {'cards': cards, 'actions': actions};
}

class DashboardLayoutRepository {
  final FirebaseFirestore? _customFirestore;

  DashboardLayoutRepository({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;

  Stream<DashboardLayout> watch(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map(
        (snapshot) =>
            DashboardLayout.fromMap(snapshot.data()?['dashboard_layout']),
      );

  Future<void> save(String userId, DashboardLayout layout) async {
    await _firestore.collection('users').doc(userId).update({
      'dashboard_layout': layout.toMap(),
    });
  }
}

final dashboardLayoutRepositoryProvider = Provider<DashboardLayoutRepository>(
  (ref) => DashboardLayoutRepository(),
);

final dashboardLayoutProvider = StreamProvider.family<DashboardLayout, String>(
  (ref, userId) => ref.read(dashboardLayoutRepositoryProvider).watch(userId),
);
