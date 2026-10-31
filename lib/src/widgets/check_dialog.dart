import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';

import 'custom_dialog_template.dart';

/// Asks for a checkbox label; pops with it or null.
class CheckDialog extends StatefulWidget {
  final RichEditorLabels labels;

  const CheckDialog({super.key, this.labels = const RichEditorLabels()});

  @override
  State<CheckDialog> createState() => _CheckDialogState();
}

class _CheckDialogState extends State<CheckDialog> {
  final _textEditingController = TextEditingController();

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialogTemplate(
      labels: widget.labels,
      body: [
        Text(widget.labels.checkboxTitle),
        TextField(controller: _textEditingController, autofocus: true),
      ],
      onDone: () => Navigator.pop(context, _textEditingController.text),
      onCancel: () => Navigator.pop(context),
    );
  }
}
