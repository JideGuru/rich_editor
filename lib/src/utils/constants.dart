import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/button.dart';

import 'javascript_executor_base.dart';

List<Button> buttons = [
  Button(
    icon: Icons.format_bold,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setBold(),
  ),
  Button(
    icon: Icons.format_italic,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setItalic(),
  ),
  Button(
    icon: Icons.link,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async {
      await javascriptExecutorBase.insertLink(
        'https://github.com/JideGuru',
        'Sample',
      );
    },
  ),
  Button(
    icon: Icons.image,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async {
      await javascriptExecutorBase.insertImage(
        'https://avatars.githubusercontent.com/u/24323581?v=4',
        alt: 'Jide',
        height: 200,
        width: 200,
      );
    },
  ),
  Button(
    icon: Icons.format_underline,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setUnderline(),
  ),
  Button(
    icon: Icons.format_strikethrough,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setStrikeThrough(),
  ),
  Button(
    icon: Icons.superscript,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setSuperscript(),
  ),
  Button(
    icon: Icons.subscript,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setSubscript(),
  ),
  Button(icon: Icons.format_clear),
  Button(
    icon: Icons.undo,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.undo(),
  ),
  Button(
    icon: Icons.redo,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.redo(),
  ),
  Button(
    icon: Icons.format_quote,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setBlockQuote(),
  ),
  Button(
    icon: Icons.text_format,
    onTap: (JavascriptExecutorBase javascriptExecutorBase, String name) async =>
        await javascriptExecutorBase.removeFormat(),
  ),
  Button(
    icon: Icons.font_download,
    onTap: (JavascriptExecutorBase javascriptExecutorBase, String name) async =>
        await javascriptExecutorBase.setFontName(name),
  ),
  Button(
    icon: Icons.format_size,
    onTap: (JavascriptExecutorBase javascriptExecutorBase, int size) async =>
        await javascriptExecutorBase.setFontSize(size),
  ),
  Button(
    icon: Icons.format_color_text,
    onTap: (JavascriptExecutorBase javascriptExecutorBase, Color color) async =>
        await javascriptExecutorBase.setTextColor(color),
  ),
  Button(
    icon: Icons.format_color_fill,
    onTap: (JavascriptExecutorBase javascriptExecutorBase, Color color) async =>
        await javascriptExecutorBase.setTextBackgroundColor(color),
  ),
  Button(
    icon: Icons.format_indent_increase,
    onTap: (JavascriptExecutorBase javascriptExecutorBase, int size) async =>
        await javascriptExecutorBase.setIndent(),
  ),
  Button(
    icon: Icons.format_indent_decrease,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setOutdent(),
  ),
  Button(
    icon: Icons.format_align_left_outlined,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setJustifyLeft(),
  ),
  Button(
    icon: Icons.format_align_center,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setJustifyCenter(),
  ),
  Button(
    icon: Icons.format_align_right,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setJustifyRight(),
  ),
  Button(
    icon: Icons.format_align_justify,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.setJustifyFull(),
  ),
  Button(
    icon: Icons.format_list_bulleted,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.insertBulletList(),
  ),
  Button(
    icon: Icons.format_list_numbered,
    onTap: (JavascriptExecutorBase javascriptExecutorBase) async =>
        await javascriptExecutorBase.insertNumberedList(),
  ),
  Button(
    icon: Icons.check_box_outlined,
    onTap: (JavascriptExecutorBase javascriptExecutorBase, String text) async =>
        await javascriptExecutorBase.insertCheckbox(text),
  ),
  Button(icon: Icons.search),
];
