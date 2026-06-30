import 'package:flutter/material.dart';

import 'package:key_budget/core/constants/app_icons.dart';

class ExpenseCategory {
  final String? id;
  final String name;
  final int iconCodePoint;
  final int colorValue;

  ExpenseCategory({
    this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
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
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseCategory(
      id: id,
      name: map['name'],
      iconCodePoint: map['iconCodePoint'],
      colorValue: map['colorValue'],
    );
  }
}
