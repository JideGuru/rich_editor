import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';

/// A block format offered by [HeadingDialog].
enum BlockFormat { h1, h2, h3, h4, h5, h6, paragraph, preformat, blockquote }

/// Lets the user pick a [BlockFormat]; pops with it or null.
class HeadingDialog extends StatelessWidget {
  final RichEditorLabels labels;

  const HeadingDialog({super.key, this.labels = const RichEditorLabels()});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final headingStyles = [
      text.headlineMedium,
      text.headlineSmall,
      text.titleLarge,
      text.titleMedium,
      text.titleSmall,
      text.labelLarge,
    ];

    Widget option(BlockFormat format, String title, TextStyle? style) {
      return ListTile(
        title: Text(title, style: style),
        onTap: () => Navigator.pop(context, format),
      );
    }

    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var level = 1; level <= 6; level++)
              option(
                BlockFormat.values[level - 1],
                '${labels.heading} $level',
                headingStyles[level - 1]?.copyWith(fontWeight: FontWeight.bold),
              ),
            option(BlockFormat.paragraph, labels.paragraph, text.bodyLarge),
            option(BlockFormat.preformat, labels.preformat,
                text.bodyLarge?.copyWith(fontFamily: 'monospace')),
            option(BlockFormat.blockquote, labels.quote,
                text.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
