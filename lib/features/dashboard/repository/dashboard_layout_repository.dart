import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DashboardCardSize {
  compact('Compacto', 104),
  regular('Médio', 144),
  large('Amplo', 208);

  const DashboardCardSize(this.label, this.chartHeight);
  final String label;
  final double chartHeight;
}

class DashboardLayout {
  static const cardIds = ['balance', 'chart', 'quick_actions', 'recent'];
  static const availableCardIds = [
    ...cardIds,
    'categories',
    'accumulated',
    'periods',
    'upcoming',
    'daily',
    'weekdays',
  ];
  static const resizableCardIds = [
    'chart',
    'categories',
    'accumulated',
    'periods',
    'upcoming',
    'daily',
    'weekdays',
  ];
  static const actionIds = ['expense', 'credentials', 'analysis', 'suppliers'];

  final List<String> cards;
  final List<String> actions;
  final bool integratedSummary;
  final Map<String, DashboardCardSize> cardSizes;

  DashboardCardSize sizeFor(String id) =>
      cardSizes[id] ?? DashboardCardSize.regular;

  const DashboardLayout({
    this.cards = cardIds,
    this.actions = actionIds,
    this.integratedSummary = true,
    this.cardSizes = const {},
  });

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

    final cards = raw['cards'] is List
        ? read('cards', availableCardIds)
        : List<String>.of(cardIds);
    if (!cards.contains('recent')) cards.add('recent');
    final sizes = <String, DashboardCardSize>{};
    final rawSizes = raw['card_sizes'];
    if (rawSizes is Map) {
      for (final id in resizableCardIds) {
        for (final size in DashboardCardSize.values) {
          if (rawSizes[id] == size.name) sizes[id] = size;
        }
      }
    }
    return DashboardLayout(
      cardSizes: sizes,
      cards: cards,
      actions: read('actions', actionIds),
      integratedSummary: raw['integrated_summary'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
    'cards': cards,
    'actions': actions,
    'integrated_summary': integratedSummary,
    'card_sizes': {
      for (final entry in cardSizes.entries)
        if (resizableCardIds.contains(entry.key)) entry.key: entry.value.name,
    },
  };
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
