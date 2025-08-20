import 'package:key_budget/core/models/expense_category.dart';

class Expense {
  final int? id;
  final int userId;
  final double amount;
  final DateTime date;
  final ExpenseCategory? category;
  final String? motivation;

  Expense({
    this.id,
    required this.userId,
    required this.amount,
    required this.date,
    this.category,
    this.motivation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category?.name,
      'motivation': motivation,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      userId: map['user_id'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'] != null
          ? ExpenseCategory.values.firstWhere((e) => e.name == map['category'])
          : null,
      motivation: map['motivation'],
    );
  }
}
