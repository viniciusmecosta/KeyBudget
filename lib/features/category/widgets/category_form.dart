import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/widgets/app_color_choice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/design_system/widgets/app_form_section_heading.dart';

import 'color_picker_widget.dart';
import 'icon_picker_widget.dart';

class CategoryForm extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final IconData? selectedIcon;
  final Color? selectedColor;
  final Function(IconData?) onIconChanged;
  final Function(Color?) onColorChanged;
  final VoidCallback? onChanged;

  const CategoryForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconChanged,
    required this.onColorChanged,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final displayColor = selectedColor ?? theme.colorScheme.primary;

    return Form(
      key: formKey,
      onChanged: onChanged,
      child: ListView(
        children: [
          const AppFormSectionHeading(
            title: 'Dados da categoria',
            icon: Icons.category_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: nameController,
            label: 'Nome da Categoria *',
            prefixIcon: Icons.label_outline,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Insira um nome' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          const AppFormSectionHeading(
            title: 'Personalização',
            icon: Icons.style_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Selecione uma cor para personalizar sua categoria:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: AppColorChoice.palette.entries
                .map(
                  (entry) => AppColorChoice(
                    color: Color(entry.key),
                    label: 'Cor ${entry.value} da categoria',
                    selected: displayColor.toARGB32() == entry.key,
                    onPressed: () => onColorChanged(Color(entry.key)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildPickerCard(
                  context: context,
                  label: 'Alterar Ícone',
                  icon: Icons.touch_app_outlined,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: displayColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selectedIcon ?? Icons.category,
                      size: 32,
                      color: displayColor,
                    ),
                  ),
                  onTap: () async {
                    final icon = await showModalBottomSheet<IconData>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => IconPickerWidget(
                        selectedColor: displayColor,
                        selectedIcon: selectedIcon,
                      ),
                      sheetAnimationStyle: AppAnimations.routeStyle(context),
                    );
                    if (icon != null) {
                      onIconChanged(icon);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildPickerCard(
                  context: context,
                  label: 'Cor Personalizada',
                  icon: Icons.palette_outlined,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: displayColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: displayColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  onTap: () async {
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (_) =>
                          ColorPickerWidget(initialColor: displayColor),
                      animationStyle: AppAnimations.routeStyle(context),
                    );
                    if (color != null) {
                      onColorChanged(color);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerCard({
    required BuildContext context,
    required String label,
    IconData? icon,
    required Widget child,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
