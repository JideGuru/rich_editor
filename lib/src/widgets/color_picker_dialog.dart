import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';

/// Lets the user pick a color, starting from [color]; pops with it or null.
class ColorPickerDialog extends StatefulWidget {
  final Color color;
  final RichEditorLabels labels;

  const ColorPickerDialog({
    super.key,
    this.color = Colors.blue,
    this.labels = const RichEditorLabels(),
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color _color = widget.color;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.all(0.0),
      contentPadding: const EdgeInsets.all(0.0),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _color,
          onColorChanged: (pickedColor) => setState(() => _color = pickedColor),
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
          onPressed: () => Navigator.pop(context),
          child: Text(widget.labels.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _color),
          child: Text(widget.labels.done),
        ),
      ],
    );
  }
}
