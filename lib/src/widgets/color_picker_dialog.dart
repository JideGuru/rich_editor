import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color? color;

  const ColorPickerDialog({super.key, this.color});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  Color? color;

  @override
  void initState() {
    super.initState();
    color = widget.color;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0.0),
      contentPadding: const EdgeInsets.all(0.0),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: color!,
          onColorChanged: (pickedColor) {
            color = pickedColor;
            setState(() {});
          },
          colorPickerWidth: 300.0,
          pickerAreaHeightPercent: 0.7,
          enableAlpha: true,
          displayThumbColor: true,
          paletteType: PaletteType.hsv,
          pickerAreaBorderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2.0),
            topRight: Radius.circular(2.0),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, color),
          child: const Text('Done'),
        )
      ],
    );
  }
}
