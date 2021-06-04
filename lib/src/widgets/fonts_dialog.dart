import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:rich_editor/src/models/system_font.dart';
import 'package:rich_editor/src/utils/font_list_parser.dart';

import 'html_text.dart';

class FontsDialog extends StatelessWidget {
  List<SystemFont> getSystemFonts() {
    return FontListParser().getSystemFonts();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (SystemFont font in getSystemFonts())
              InkWell(
                child: HtmlText(
                    html: '<p style="font-family:${font.name}">'
                        '${basename(font.path!)}</p>'),
                onTap: () {
                  Navigator.pop(context, font.name);
                },
              )
          ],
        ),
      ),
    );
  }
}
