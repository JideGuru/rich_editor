import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';

import 'custom_dialog_template.dart';

/// Asks for a link; pops with the entered `(url, label)` or null.
class InsertLinkDialog extends StatefulWidget {
  final RichEditorLabels labels;

  const InsertLinkDialog({super.key, this.labels = const RichEditorLabels()});

  @override
  State<InsertLinkDialog> createState() => _InsertLinkDialogState();
}

class _InsertLinkDialogState extends State<InsertLinkDialog> {
  final _link = TextEditingController();
  final _label = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    return CustomDialogTemplate(
      labels: labels,
      body: [
        Text(labels.link),
        TextField(
          controller: _link,
          keyboardType: TextInputType.url,
          autofocus: true,
          decoration: InputDecoration(hintText: labels.linkHint),
        ),
        const SizedBox(height: 20.0),
        Text(labels.linkLabel),
        TextField(
          controller: _label,
          decoration: InputDecoration(hintText: labels.linkLabelHint),
        ),
      ],
      onDone: () => Navigator.pop<({String url, String label})>(
          context, (url: _link.text.trim(), label: _label.text)),
      onCancel: () => Navigator.pop(context),
    );
  }
}
