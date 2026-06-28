import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryAutocompleteField extends ConsumerWidget {
  final String label;
  final TextEditingController controller;
  final AutocompleteOptionsBuilder<String> optionsBuilder;
  final void Function(String) onSelected;
  final int maxLines;
  final TextCapitalization textCapitalization;

  const CategoryAutocompleteField({
    super.key,
    required this.label,
    required this.controller,
    required this.optionsBuilder,
    required this.onSelected,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: optionsBuilder,
      onSelected: onSelected,
      fieldViewBuilder:
          (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
        if (controller.text != fieldTextEditingController.text) {
          fieldTextEditingController.text = controller.text;
        }
        return TextFormField(
          controller: fieldTextEditingController,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          decoration: InputDecoration(labelText: label),
          onChanged: (value) => controller.text = value,
          maxLines: maxLines,
        );
      },
    );
  }
}
