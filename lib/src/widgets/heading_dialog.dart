import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class HeadingDialog extends StatelessWidget {
  List formats = [
    {'id': '1', 'title': '<h1>Heading 1</h1>'},
    {'id': '2', 'title': '<h2>Heading 2</h2>'},
    {'id': '3', 'title': '<h3>Heading 3</h3>'},
    {'id': '4', 'title': '<h4>Heading 4</h4>'},
    {'id': '5', 'title': '<h5>Heading 5</h5>'},
    {'id': '6', 'title': '<h6>Heading 6</h6>'},
    {'id': 'p', 'title': '<p>Text body</p>'},
    {
      'id': 'pre',
      'title': '<pre><font face=\"courier\">Preformat</font></pre>'
    },
    {'id': 'blockquote', 'title': '<blockquote>Quote</blockquote>'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (Map format in formats)
          InkWell(
            child: Html(data: format['title']),
            onTap: () => Navigator.pop(context, format['id']),
          )
      ],
    );
  }
}
