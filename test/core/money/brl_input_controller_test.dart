import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/money/brl_input_controller.dart';

void main() {
  test(
    'cent entry, paste and clear keep Brazilian currency and exact cents',
    () {
      final controller = BrlInputController();
      addTearDown(controller.dispose);
      controller.text = '123456';
      expect(controller.text, 'R\$ 1.234,56');
      expect(controller.amountMinor, 123456);
      controller.text = 'R\$ 9.876,54';
      expect(controller.amountMinor, 987654);
      controller.clear();
      expect(controller.text, 'R\$ 0,00');
      expect(controller.amountMinor, 0);
      controller.text = '1';
      expect(controller.text, 'R\$ 0,01');
    },
  );

  test('editing in the middle preserves cursor relative to digits', () {
    final controller = BrlInputController(initialValue: 1234.56);
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
      text: 'R\$ 1.934,56',
      selection: TextSelection.collapsed(offset: 6),
    );
    expect(controller.amountMinor, 193456);
    expect(controller.selection.baseOffset, 6);
    controller.value = const TextEditingValue(
      text: 'R\$ 1934,56',
      selection: TextSelection.collapsed(offset: 5),
    );
    expect(controller.text, 'R\$ 1.934,56');
    expect(controller.selection.baseOffset, 6);
  });
}
