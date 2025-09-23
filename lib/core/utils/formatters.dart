import 'package:flutter/services.dart';

class PasteSanitizerInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final isPasted = newValue.text.length > oldValue.text.length + 1;
    if (isPasted) {
      String text = newValue.text;
      String sanitizedText = text.replaceAll(RegExp(r'[^0-9]'), '');

      if (sanitizedText.startsWith('55')) {
        sanitizedText = sanitizedText.substring(2);
      }

      return TextEditingValue(
        text: sanitizedText,
        selection: TextSelection.collapsed(offset: sanitizedText.length),
      );
    }
    return newValue;
  }
}
