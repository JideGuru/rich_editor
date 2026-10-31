import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';

/// Lets the user pick a font size from 1 to 7; pops with it or null.
class FontSizeDialog extends StatelessWidget {
  final RichEditorLabels labels;

  const FontSizeDialog({super.key, this.labels = const RichEditorLabels()});

  // Roughly the sizes the editor renders for font sizes 1 to 7.
  static const _previewSizes = [10.0, 13.0, 16.0, 18.0, 24.0, 32.0, 48.0];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var size = 1; size <= 7; size++)
              ListTile(
                title: Text(
                  labels.fontSizes[size - 1],
                  style: TextStyle(fontSize: _previewSizes[size - 1]),
                ),
                onTap: () => Navigator.pop(context, size),
              ),
          ],
        ),
      ),
    );
  }
}
