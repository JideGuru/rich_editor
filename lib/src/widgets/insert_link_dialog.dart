import 'package:flutter/material.dart';

import 'custom_dialog_template.dart';

class InsertLinkDialog extends StatelessWidget {
  final link = TextEditingController();
  final label = TextEditingController();

  InsertLinkDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomDialogTemplate(
      body: [
        const Text('Link'),
        TextField(
          controller: link,
          decoration: const InputDecoration(
            hintText: 'type link here',
          ),
        ),
        const SizedBox(height: 20.0),
        const Text('Label'),
        TextField(
          controller: label,
          decoration: const InputDecoration(
            hintText: 'type label text here',
          ),
        ),
      ],
      onDone: () => Navigator.pop(context, [link.text, label.text]),
      onCancel: () => Navigator.pop(context),
    );
  }
}
