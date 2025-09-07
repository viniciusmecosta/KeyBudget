import 'package:flutter/material.dart';

class CategoryAutocompleteField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> Function() optionsBuilder;
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
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final suggestions = optionsBuilder();
        if (textEditingValue.text.isEmpty) {
          return suggestions;
        }
        return suggestions.where((String option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: onSelected,
      fieldViewBuilder:
          (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
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
