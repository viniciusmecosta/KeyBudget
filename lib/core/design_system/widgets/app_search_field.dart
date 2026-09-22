import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/borders/app_borders.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('searchBox'),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppBorders.borderRadiusXL,
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          suffixIcon: IconButton(
            tooltip: 'Limpar busca',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
