import 'package:flutter/material.dart';

class InsertLinkDialog extends StatelessWidget {
  TextEditingController link = TextEditingController();
  TextEditingController label = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Insert Link'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, [link.text, label.text]),
          child: Text('Done'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
