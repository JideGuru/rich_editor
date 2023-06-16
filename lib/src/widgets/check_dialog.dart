import 'package:flutter/material.dart';

import 'custom_dialog_template.dart';

class CheckDialog extends StatelessWidget {
  CheckDialog();
  final _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CustomDialogTemplate(
      body: [
        Text('Checkbox title'),
        TextField(
          controller: _textEditingController,
          decoration: InputDecoration(hintText: ''),
        ),
      ],
      onDone: () => Navigator.pop(context, _textEditingController.text),
      onCancel: () => Navigator.pop(context),
    );
  }
}
