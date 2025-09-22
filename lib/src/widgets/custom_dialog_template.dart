import 'package:flutter/material.dart';

class CustomDialogTemplate extends StatelessWidget {
  final List<Widget>? body;
  final Function? onDone;
  final Function? onCancel;

  const CustomDialogTemplate(
      {super.key, this.body, this.onDone, this.onCancel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: body!,
      ),
      actions: [
        TextButton(
          onPressed: () => onDone!(),
          child: const Text('Done'),
        ),
        TextButton(
          onPressed: () => onCancel!(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
