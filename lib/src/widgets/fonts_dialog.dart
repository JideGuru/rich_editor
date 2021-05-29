import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class FontsDialog extends StatelessWidget {
  List fonts = [
    {
      'id': 'cursive',
      'title': '<p style="font-family:cursive">This is a paragraph.</p>'
    },
    {
      'id': 'monospace',
      'title': '<p style="font-family:monospace">This is a paragraph.</p>'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (Map font in fonts)
              InkWell(
                child: Html(data: font['title']),
                onTap: () => Navigator.pop(context, font['id']),
              )
          ],
        ),
      ),
    );
  }
}
