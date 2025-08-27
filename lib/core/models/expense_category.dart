import 'package:flutter/material.dart';

import '../../app/config/app_theme.dart';

enum ExpenseCategory { alimentacao, lazer, roupa, farmacia, transporte, outros }

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.roupa:
        return 'Roupa';
      case ExpenseCategory.alimentacao:
        return 'Alimentação';
      case ExpenseCategory.lazer:
        return 'Lazer';
      case ExpenseCategory.farmacia:
        return 'Farmácia';
      case ExpenseCategory.transporte:
        return 'Transporte';
      case ExpenseCategory.outros:
        return 'Outros';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.alimentacao:
        return Icons.restaurant;
      case ExpenseCategory.roupa:
        return Icons.checkroom;
      case ExpenseCategory.lazer:
        return Icons.shopping_bag;
      case ExpenseCategory.farmacia:
        return Icons.medication_rounded;
      case ExpenseCategory.transporte:
        return Icons.directions_bus;
      case ExpenseCategory.outros:
        return Icons.category_rounded;
    }
  }

  Color getColor(ThemeData theme) {
    final index = ExpenseCategory.values.indexOf(this);
    return AppTheme.chartColors[index % AppTheme.chartColors.length];
  }
}
