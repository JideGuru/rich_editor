import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
import 'package:rich_editor/src/widgets/check_dialog.dart';
import 'package:rich_editor/src/widgets/fonts_dialog.dart';
import 'package:rich_editor/src/widgets/insert_image_dialog.dart';
import 'package:rich_editor/src/widgets/insert_link_dialog.dart';
import 'package:rich_editor/src/widgets/tab_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'color_picker_dialog.dart';
import 'font_size_dialog.dart';
import 'heading_dialog.dart';

class EditorToolBar extends StatelessWidget {
  final WebViewController? controller;
  final Function(File image)? getImageUrl;
  final Function(File video)? getVideoUrl;
  final JavascriptExecutorBase javascriptExecutorBase;

  EditorToolBar({
    this.controller,
    this.getImageUrl,
    this.getVideoUrl,
    required this.javascriptExecutorBase,
  });

  @override
  Widget build(BuildContext context) {
    // if (controller != null) {
    //   javascriptExecutorBase.init(controller!);
    // }

    return Container(
      // color: Color(0xff424242),
      height: 54.0,
      child: Column(
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: [
                TabButton(
                  tooltip: 'Bold',
                  icon: Icons.format_bold,
                  onTap: () async {
                    await javascriptExecutorBase.setBold();
                  },
                ),
                TabButton(
                  tooltip: 'Italic',
                  icon: Icons.format_italic,
                  onTap: () async {
                    await javascriptExecutorBase.setItalic();
                  },
                ),
                TabButton(
                  tooltip: 'Insert Link',
                  icon: Icons.link,
                  onTap: () async {
                    _closeKeyboard();
                    var link = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) {
                        return InsertLinkDialog();
                      },
                    );
                    if (link != null)
                      await javascriptExecutorBase.insertLink(link[0], link[1]);
                  },
                ),
                TabButton(
                  tooltip: 'Insert Image',
                  icon: Icons.image,
                  onTap: () async {
                    _closeKeyboard();
                    var link = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) {
                        return InsertImageDialog();
                      },
                    );
                    if (link != null) {
                      if (getImageUrl != null && link[2]) {
                        link[0] = await getImageUrl!(File(link[0]));
                      }
                      await javascriptExecutorBase.insertImage(
                        link[0],
                        alt: link[1],
                      );
                    }
                  },
                ),
                TabButton(
                  tooltip: 'Underline',
                  icon: Icons.format_underline,
                  onTap: () async {
                    await javascriptExecutorBase.setUnderline();
                  },
                ),
                TabButton(
                  tooltip: 'Strike through',
                  icon: Icons.format_strikethrough,
                  onTap: () async {
                    await javascriptExecutorBase.setStrikeThrough();
                  },
                ),
                TabButton(
                  tooltip: 'Superscript',
                  icon: Icons.superscript,
                  onTap: () async {
                    await javascriptExecutorBase.setSuperscript();
                  },
                ),
                TabButton(
                  tooltip: 'Subscript',
                  icon: Icons.subscript,
                  onTap: () async {
                    await javascriptExecutorBase.setSubscript();
                  },
                ),
                TabButton(
                  tooltip: 'Clear format',
                  icon: Icons.format_clear,
                  onTap: () async {
                    await javascriptExecutorBase.removeFormat();
                  },
                ),
                TabButton(
                  tooltip: 'Undo',
                  icon: Icons.undo,
                  onTap: () async {
                    await javascriptExecutorBase.undo();
                  },
                ),
                TabButton(
                  tooltip: 'Redo',
                  icon: Icons.redo,
                  onTap: () async {
                    await javascriptExecutorBase.redo();
                  },
                ),
                TabButton(
                  tooltip: 'Blockquote',
                  icon: Icons.format_quote,
                  onTap: () async {
                    await javascriptExecutorBase.setBlockQuote();
                  },
                ),
                TabButton(
                  tooltip: 'Font format',
                  icon: Icons.text_format,
                  onTap: () async {
                    _closeKeyboard();
                    var command = await showDialog(
                      // isScrollControlled: true,
                      context: context,
                      builder: (_) {
                        return HeadingDialog();
                      },
                    );
                    if (command != null) {
                      if (command == 'p') {
                        await javascriptExecutorBase.setFormattingToParagraph();
                      } else if (command == 'pre') {
                        await javascriptExecutorBase.setPreformat();
                      } else if (command == 'blockquote') {
                        await javascriptExecutorBase.setBlockQuote();
                      } else {
                        await javascriptExecutorBase
                            .setHeading(int.tryParse(command)!);
                      }
                    }
                  },
                ),
                // TODO: Show font button on iOS
                Visibility(
                  visible: Platform.isAndroid,
                  child: TabButton(
                    tooltip: 'Font face',
                    icon: Icons.font_download,
                    onTap: () async {
                      Directory fontsDir = Directory("/system/fonts/");
                      File file = File('/system/etc/fonts.xml');
                      // debugPrint(await file.readAsString());
                      var command = await showDialog(
                        // isScrollControlled: true,
                        context: context,
                        builder: (_) {
                          return FontsDialog();
                        },
                      );
                      if (command != null)
                        await javascriptExecutorBase.setFontName(command);
                    },
                  ),
                ),
                TabButton(
                  icon: Icons.format_size,
                  tooltip: 'Font Size',
                  onTap: () async {
                    _closeKeyboard();
                    String? command = await showDialog(
                      // isScrollControlled: true,
                      context: context,
                      builder: (_) {
                        return FontSizeDialog();
                      },
                    );
                    if (command != null)
                      await javascriptExecutorBase
                          .setFontSize(int.tryParse(command)!);
                  },
                ),
                TabButton(
                  tooltip: 'Text Color',
                  icon: Icons.format_color_text,
                  onTap: () async {
                    _closeKeyboard();
                    var color = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ColorPickerDialog(color: Colors.blue);
                      },
                    );
                    if (color != null)
                      await javascriptExecutorBase.setTextColor(color);
                  },
                ),
                TabButton(
                  tooltip: 'Background Color',
                  icon: Icons.format_color_fill,
                  onTap: () async {
                    _closeKeyboard();
                    var color = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ColorPickerDialog(color: Colors.blue);
                      },
                    );
                    if (color != null)
                      await javascriptExecutorBase
                          .setTextBackgroundColor(color);
                  },
                ),
                TabButton(
                  tooltip: 'Increase Indent',
                  icon: Icons.format_indent_increase,
                  onTap: () async {
                    await javascriptExecutorBase.setIndent();
                  },
                ),
                TabButton(
                  tooltip: 'Decrease Indent',
                  icon: Icons.format_indent_decrease,
                  onTap: () async {
                    await javascriptExecutorBase.setOutdent();
                  },
                ),
                TabButton(
                  tooltip: 'Align Left',
                  icon: Icons.format_align_left_outlined,
                  onTap: () async {
                    await javascriptExecutorBase.setJustifyLeft();
                  },
                ),
                TabButton(
                  tooltip: 'Align Center',
                  icon: Icons.format_align_center,
                  onTap: () async {
                    await javascriptExecutorBase.setJustifyCenter();
                  },
                ),
                TabButton(
                  tooltip: 'Align Right',
                  icon: Icons.format_align_right,
                  onTap: () async {
                    await javascriptExecutorBase.setJustifyRight();
                  },
                ),
                TabButton(
                  tooltip: 'Justify',
                  icon: Icons.format_align_justify,
                  onTap: () async {
                    await javascriptExecutorBase.setJustifyFull();
                  },
                ),
                TabButton(
                  tooltip: 'Bullet List',
                  icon: Icons.format_list_bulleted,
                  onTap: () async {
                    await javascriptExecutorBase.insertBulletList();
                  },
                ),
                TabButton(
                  tooltip: 'Numbered List',
                  icon: Icons.format_list_numbered,
                  onTap: () async {
                    await javascriptExecutorBase.insertNumberedList();
                  },
                ),
                TabButton(
                  tooltip: 'Checkbox',
                  icon: Icons.check_box_outlined,
                  onTap: () async {
                    _closeKeyboard();
                    var text = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CheckDialog();
                      },
                    );
                    print(text);
                    if (text != null)
                      await javascriptExecutorBase.insertCheckbox(text);
                  },
                ),

                /// TODO: Implement Search feature
                // TabButton(
                //   tooltip: 'Search',
                //   icon: Icons.search,
                //   onTap: () async {
                //     // await javascriptExecutorBase.insertNumberedList();
                //   },
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hide the keyboard using JavaScript since it's being opened in a WebView
  // https://stackoverflow.com/a/8263376/10835183
  _closeKeyboard() async {
    // controller!.evaluateJavascript('document.activeElement.blur();');
  }
}
