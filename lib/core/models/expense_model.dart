class Expense {
  final int? id;
  final int userId;
  final String description;
  final double amount;
  final DateTime date;
  final String? category;

  Expense({
    this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.date,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      userId: map['user_id'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'],
    );
  }
}
