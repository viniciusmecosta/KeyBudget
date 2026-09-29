import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/features/dashboard/repository/dashboard_layout_repository.dart';

void main() {
  test('legacy profile uses the complete default panel', () {
    final layout = DashboardLayout.fromMap(null);
    expect(layout.cards, DashboardLayout.cardIds);
    expect(layout.actions, DashboardLayout.actionIds);
  });

  test('saved order is kept while invalid ids and duplicates are removed', () {
    final layout = DashboardLayout.fromMap({
      'cards': ['chart', 'chart', 'unknown', 'balance'],
      'actions': ['analysis', 'expense', 'analysis', 'unknown'],
    });
    expect(layout.cards, ['chart', 'balance', 'recent']);
    expect(layout.actions, ['analysis', 'expense']);
    expect(DashboardLayout.fromMap(layout.toMap()).cards, layout.cards);
  });
}
