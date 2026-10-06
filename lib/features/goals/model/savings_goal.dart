import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoal {
  final String id;
  final String name;
  final int targetMinor;
  final int savedMinor;
  final DateTime createdAt;
  final DateTime? deadline;
  final bool isArchived;
  final bool isDeleting;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetMinor,
    required this.savedMinor,
    required this.createdAt,
    this.deadline,
    this.isArchived = false,
    this.isDeleting = false,
  });

  int get remainingMinor => targetMinor - savedMinor;
  double get progress => targetMinor <= 0 ? 0 : savedMinor / targetMinor;
  bool get isComplete => savedMinor >= targetMinor;

  factory SavingsGoal.fromMap(String id, Map<String, dynamic> data) {
    DateTime readDate(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      throw const FormatException('Data inválida na meta.');
    }

    final target = data['targetMinor'];
    final saved = data['savedMinor'];
    if (target is! int || target <= 0 || saved is! int || saved < 0) {
      throw const FormatException('Valores inválidos na meta.');
    }
    final name = data['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Nome inválido na meta.');
    }
    return SavingsGoal(
      id: id,
      name: name,
      targetMinor: target,
      savedMinor: saved,
      createdAt: readDate(data['createdAt']),
      deadline: data['deadline'] == null ? null : readDate(data['deadline']),
      isArchived: data['archived'] == true,
      isDeleting: data['deleting'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'targetMinor': targetMinor,
    'savedMinor': savedMinor,
    'createdAt': Timestamp.fromDate(createdAt),
    'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
    'archived': isArchived,
    'deleting': isDeleting,
  };
}
