import 'package:flutter/material.dart';

import 'custom_dialog_template.dart';

class CheckDialog extends StatelessWidget {
  TextEditingController text = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CustomDialogTemplate(
      body: [
        Text('Checkbox title'),
        TextField(
          controller: text,
          decoration: InputDecoration(hintText: ''),
        ),
      ],
      onDone: () => Navigator.pop(context, text.text),
      onCancel: () => Navigator.pop(context),
    );
  }
}
