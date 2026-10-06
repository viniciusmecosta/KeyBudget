import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/features/trash/repository/trash_repository.dart';

void main() {
  test('trash entry remains restorable until the 30-day deadline', () {
    final deletedAt = DateTime.utc(2026, 1, 1, 12);
    final entry = TrashEntry(
      id: 'item',
      collection: 'expenses',
      title: 'Despesa',
      deletedAt: deletedAt,
      records: const [],
    );

    expect(entry.expiresAt, deletedAt.add(const Duration(days: 30)));
    expect(
      entry.isExpiredAt(
        entry.expiresAt.subtract(const Duration(milliseconds: 1)),
      ),
      isFalse,
    );
    expect(entry.isExpiredAt(entry.expiresAt), isTrue);
    expect(
      entry.isExpiredAt(entry.expiresAt.add(const Duration(days: 1))),
      isTrue,
    );
  });
}
