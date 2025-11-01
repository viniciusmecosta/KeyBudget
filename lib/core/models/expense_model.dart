class Expense {
  final String? id;
  final double amount;
  final DateTime date;
  final String? categoryId;
  final String? motivation;
  final String? location;

  Expense({
    this.id,
    required this.amount,
    required this.date,
    this.categoryId,
    this.motivation,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'motivation': motivation,
      'location': location,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      categoryId: map['categoryId'],
      motivation: map['motivation'],
      location: map['location'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          date == other.date &&
          categoryId == other.categoryId &&
          motivation == other.motivation &&
          location == other.location;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      date.hashCode ^
      categoryId.hashCode ^
      motivation.hashCode ^
      location.hashCode;
}
