import 'package:flutter/widgets.dart';
import 'money.dart';

/// Cent-based monetary entry. Keeps the cursor beside the edited digit when
/// grouping separators change; clearing the field is always safe.
class BrlInputController extends TextEditingController {
  BrlInputController({
    double initialValue = 0,
    this.allowCursorEditing = false,
  }) {
    updateValue(initialValue);
  }

  final bool allowCursorEditing;

  static final _nonDigits = RegExp(r'[^0-9]');
  int get amountMinor => int.tryParse(text.replaceAll(_nonDigits, '')) ?? 0;
  double get numberValue => amountMinor / 100;

  void updateValue(double amount) {
    final cents = Money.fromNumWithHalfAwayFromZero(amount).amountMinor;
    final formatted = _format(cents.abs());
    super.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _format(int cents) {
    final digits = cents.toString().padLeft(3, '0');
    final whole = digits
        .substring(0, digits.length - 2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (match) => '${match[1]}.',
        );
    return 'R\$ $whole,${digits.substring(digits.length - 2)}';
  }

  @override
  set value(TextEditingValue next) {
    if (next.text == text) {
      super.value = allowCursorEditing
          ? next
          : next.copyWith(
              selection: TextSelection.collapsed(offset: text.length),
            );
      return;
    }
    final digits = next.text.replaceAll(_nonDigits, '');
    // Bound input to the precision supported by existing financial operations.
    if (digits.length > 14) return;
    final formatted = _format(int.tryParse(digits) ?? 0);
    int mapOffset(int offset) {
      if (!allowCursorEditing || offset < 0) return formatted.length;
      final trailingDigits = next.text
          .substring(offset.clamp(0, next.text.length))
          .replaceAll(_nonDigits, '')
          .length;
      var remaining = trailingDigits;
      var cursor = formatted.length;
      while (cursor > 3 && remaining > 0) {
        cursor--;
        if (RegExp(r'[0-9]').hasMatch(formatted[cursor])) remaining--;
      }
      return cursor;
    }

    super.value = TextEditingValue(
      text: formatted,
      selection: TextSelection(
        baseOffset: mapOffset(next.selection.baseOffset),
        extentOffset: mapOffset(next.selection.extentOffset),
      ),
      composing: TextRange.empty,
    );
  }
}
