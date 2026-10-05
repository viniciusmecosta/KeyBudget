import 'package:flutter/material.dart';
import 'package:key_budget/core/constants/app_icons.dart';

class ExpenseCategory {
  final String? id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final bool isArchived;

  ExpenseCategory({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.isArchived = false,
  });

  IconData get icon {
    return AppIcons.all.firstWhere(
      (icon) => icon.codePoint == iconCodePoint,
      orElse: () => Icons.category,
    );
  }

  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'archived': isArchived,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseCategory(
      id: id,
      name: map['name'],
      iconCodePoint: map['iconCodePoint'],
      colorValue: map['colorValue'],
      isArchived: map['archived'] == true,
    );
  }

  factory ExpenseCategory.uncategorized() {
    return ExpenseCategory(
      id: 'uncategorized',
      name: 'Sem categoria',
      iconCodePoint: Icons.help_outline.codePoint,
      colorValue: Colors.grey.toARGB32(),
    );
  }

  factory ExpenseCategory.orphan(String orphanId) {
    return ExpenseCategory(
      id: 'orphan_$orphanId',
      name: 'Categoria removida',
      iconCodePoint: Icons.delete_outline.codePoint,
      colorValue: Colors.blueGrey.toARGB32(),
    );
  }

  bool get isSpecialGroup =>
      id == 'uncategorized' || (id?.startsWith('orphan_') ?? false);

  ExpenseCategory copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    bool? isArchived,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategory &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => (id ?? name).hashCode;
}
