import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/rich_editor_labels.dart';

class CustomDialogTemplate extends StatelessWidget {
  final List<Widget> body;
  final VoidCallback onDone;
  final VoidCallback onCancel;
  final RichEditorLabels labels;

  const CustomDialogTemplate({
    super.key,
    required this.body,
    required this.onDone,
    required this.onCancel,
    this.labels = const RichEditorLabels(),
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: body,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(labels.cancel),
        ),
        TextButton(
          onPressed: onDone,
          child: Text(labels.done),
        ),
      ],
    );
  }
}
