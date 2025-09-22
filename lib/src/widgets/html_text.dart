import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

class HtmlText extends StatelessWidget {
  final String html;

  const HtmlText({super.key, required this.html});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0,
      child: HtmlWidget(html),
    );
  }
}
