import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerWidget extends StatefulWidget {
  final Color? initialColor;

  const ColorPickerWidget({super.key, this.initialColor});

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor ?? Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecione uma Cor'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _currentColor,
          onColorChanged: (color) {
            setState(() => _currentColor = color);
          },
          pickerAreaHeightPercent: 0.8,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Selecionar'),
          onPressed: () => Navigator.of(context).pop(_currentColor),
        ),
      ],
    );
  }
}
