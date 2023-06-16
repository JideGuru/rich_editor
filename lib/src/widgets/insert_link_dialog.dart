import 'package:flutter/material.dart';

import 'custom_dialog_template.dart';

class InsertLinkDialog extends StatelessWidget {
  final link = TextEditingController();
  final label = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CustomDialogTemplate(
      body: [
        Text('Link'),
        TextField(
          controller: link,
          decoration: InputDecoration(
            hintText: 'type link here',
          ),
        ),
        SizedBox(height: 20.0),
        Text('Label'),
        TextField(
          controller: label,
          decoration: InputDecoration(
            hintText: 'type label text here',
          ),
        ),
      ],
      onDone: () => Navigator.pop(context, [link.text, label.text]),
      onCancel: () => Navigator.pop(context),
    );
  }
}
