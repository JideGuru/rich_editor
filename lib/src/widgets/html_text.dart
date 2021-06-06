import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class HtmlText extends StatelessWidget {
  final String html;

  HtmlText({required this.html});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: HtmlWidget(html),
      height: 40.0,
    );
  }
}
