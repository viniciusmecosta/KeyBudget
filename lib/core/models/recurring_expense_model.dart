import 'package:cloud_firestore/cloud_firestore.dart';

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

class RecurringExpense {
  final String? id;
  final double amount;
  final String? categoryId;
  final String? motivation;
  final String? location;
  final RecurrenceFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final int? monthOfYear;
  final DateTime? lastInstanceDate;

  RecurringExpense({
    this.id,
    required this.amount,
    this.categoryId,
    this.motivation,
    this.location,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.dayOfWeek,
    this.dayOfMonth,
    this.monthOfYear,
    this.lastInstanceDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'motivation': motivation,
      'location': location,
      'frequency': frequency.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'dayOfWeek': dayOfWeek,
      'dayOfMonth': dayOfMonth,
      'monthOfYear': monthOfYear,
      'lastInstanceDate': lastInstanceDate != null
          ? Timestamp.fromDate(lastInstanceDate!)
          : null,
    };
  }

  factory RecurringExpense.fromMap(Map<String, dynamic> map, String id) {
    return RecurringExpense(
      id: id,
      amount: map['amount']?.toDouble() ?? 0.0,
      categoryId: map['categoryId'],
      motivation: map['motivation'],
      location: map['location'],
      frequency: RecurrenceFrequency.values
          .firstWhere((e) => e.name == map['frequency']),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      dayOfWeek: map['dayOfWeek'],
      dayOfMonth: map['dayOfMonth'],
      monthOfYear: map['monthOfYear'],
      lastInstanceDate: (map['lastInstanceDate'] as Timestamp?)?.toDate(),
    );
  }
}
