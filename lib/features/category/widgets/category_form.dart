import 'package:flutter/material.dart';

import 'color_picker_widget.dart';
import 'icon_picker_widget.dart';

class CategoryForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final IconData? selectedIcon;
  final Color? selectedColor;
  final Function(IconData?) onIconChanged;
  final Function(Color?) onColorChanged;

  const CategoryForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.selectedIcon,
    required this.selectedColor,
    required this.onIconChanged,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nome da Categoria *'),
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final icon = await showModalBottomSheet<IconData>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const IconPickerWidget(),
                    );
                    if (icon != null) {
                      onIconChanged(icon);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Ícone',
                      contentPadding: EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: Center(
                      child: Icon(
                        selectedIcon ?? Icons.category,
                        size: 36,
                        color:
                            selectedColor ?? theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (_) =>
                          ColorPickerWidget(initialColor: selectedColor),
                    );
                    if (color != null) {
                      onColorChanged(color);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Cor',
                      contentPadding: EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: Center(
                      child: CircleAvatar(
                        backgroundColor: selectedColor ?? Colors.grey,
                        radius: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
