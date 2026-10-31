import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';
import 'package:rich_editor/src/models/system_font.dart';
import 'package:rich_editor/src/utils/font_list_parser.dart';

/// Lets the user pick a system font; pops with its name or null.
class FontsDialog extends StatelessWidget {
  final RichEditorLabels labels;

  const FontsDialog({super.key, this.labels = const RichEditorLabels()});

  // Reading fonts.xml is slow and its content doesn't change while the app
  // runs, so it is read once, off the build.
  static Future<List<SystemFont>>? _systemFonts;

  static Future<List<SystemFont>> _loadSystemFonts() {
    return _systemFonts ??=
        Isolate.run(() => FontListParser().safelyGetSystemFonts());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: FutureBuilder<List<SystemFont>>(
        future: _loadSystemFonts(),
        builder: (context, snapshot) {
          final fonts = snapshot.data;
          if (fonts == null) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (fonts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(labels.noFonts),
            );
          }
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final font in fonts)
                  ListTile(
                    title: Text(font.name),
                    subtitle: Text(font.path.split('/').last),
                    onTap: () => Navigator.pop(context, font.name),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
