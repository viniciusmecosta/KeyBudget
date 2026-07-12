import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';

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
          Row(
            children: [
              Icon(Icons.category_outlined, color: theme.colorScheme.onSurface, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'DADOS DA CATEGORIA',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: nameController,
            label: 'Nome da Categoria *',
            prefixIcon: Icons.label_outline,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            validator: (value) => (value == null || value.isEmpty) ? 'Insira um nome' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.style_outlined, color: theme.colorScheme.onSurface, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'PERSONALIZAÇÃO',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
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
            children: [
              0xFF3B82F6, // Blue
              0xFF10B981, // Emerald
              0xFFF59E0B, // Amber
              0xFFEF4444, // Red
              0xFF8B5CF6, // Violet
              0xFFEC4899, // Pink
              0xFF14B8A6, // Teal
              0xFF64748B, // Slate
            ].map((colorValue) {
              final isSelected = displayColor.toARGB32() == colorValue;
              return GestureDetector(
                onTap: () => onColorChanged(Color(colorValue)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 36 : 32,
                  height: isSelected ? 36 : 32,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Color(colorValue).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                    border: isSelected ? Border.all(color: theme.colorScheme.surface, width: 2) : null,
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                ),
              );
            }).toList(),
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
                      builder: (_) => IconPickerWidget(selectedColor: displayColor),
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
                      builder: (_) => ColorPickerWidget(initialColor: displayColor),
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
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
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
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );
  }

}
