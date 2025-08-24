import 'package:flutter/material.dart';

enum ExpenseCategory {
  internet,
  pizza,
  alimentacao,
  lazer,
  roupa,
  agua,
  farmacia,
  outros
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.agua:
        return 'Água';
      case ExpenseCategory.internet:
        return 'Internet';
      case ExpenseCategory.pizza:
        return 'Pizza';
      case ExpenseCategory.roupa:
        return 'Roupa';
      case ExpenseCategory.alimentacao:
        return 'Alimentação';
      case ExpenseCategory.lazer:
        return 'Lazer';
      case ExpenseCategory.farmacia:
        return 'Farmácia';
      case ExpenseCategory.outros:
        return 'Outros';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.alimentacao:
        return Icons.restaurant;
      case ExpenseCategory.internet:
        return Icons.wifi;
      case ExpenseCategory.pizza:
        return Icons.local_pizza;
      case ExpenseCategory.agua:
        return Icons.water_drop;
      case ExpenseCategory.roupa:
        return Icons.checkroom;
      case ExpenseCategory.lazer:
        return Icons.local_mall;
        case ExpenseCategory.farmacia:
          return Icons.local_pharmacy_rounded;
      case ExpenseCategory.outros:
        return Icons.category;
    }
  }
}
