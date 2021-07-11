import 'package:flutter/material.dart';

import 'html_text.dart';

class FontSizeDialog extends StatelessWidget {
  List formats = [
    {'id': '1', 'title': '<small><small><small>Teeny</small></small></small>'},
    {'id': '2', 'title': '<small><small>Very small</small></small>'},
    {'id': '3', 'title': '<small>Small</small>'},
    {'id': '4', 'title': 'Medium'},
    {'id': '5', 'title': '<big>Large</big>'},
    {'id': '6', 'title': '<big><big>Very large</big></big>'},
    {'id': '7', 'title': '<big><big><big>Huge</big></big></big>'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (Map format in formats)
              InkWell(
                child: HtmlText(html: format['title']),
                onTap: () => Navigator.pop(context, format['id']),
              )
          ],
        ),
      ),
    );
  }
}
