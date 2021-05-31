import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path/path.dart';
import 'package:rich_editor/src/models/system_font.dart';
import 'package:rich_editor/src/utils/font_list_parser.dart';

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
                child: Html(data: '<p style="font-family:${font.name}">'
                    '${basename(font.path!)}</p>'),
                onTap: () => Navigator.pop(context, font.path),
              )
          ],
        ),
      ),
    );
  }

  fontSlug(FileSystemEntity font) {
    String name = basename(font.path);
    String slug = name.toLowerCase();
    slug = slug.replaceAll(extension(font.path), '');
    // print(slug);
    return slug;
  }
}
