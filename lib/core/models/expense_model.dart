import 'package:key_budget/core/models/expense_category.dart';

class Expense {
  final String? id;
  final double amount;
  final DateTime date;
  final ExpenseCategory? category;
  final String? motivation;
  final String? location;

  Expense({
    this.id,
    required this.amount,
    required this.date,
    this.category,
    this.motivation,
    this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category?.name,
      'motivation': motivation,
      'location': location,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'] != null
          ? ExpenseCategory.values.firstWhere((e) => e.name == map['category'])
          : null,
      motivation: map['motivation'],
      location: map['location'],
    );
  }
}
