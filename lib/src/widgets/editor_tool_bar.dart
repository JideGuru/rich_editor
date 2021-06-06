import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
import 'package:rich_editor/src/widgets/check_dialog.dart';
import 'package:rich_editor/src/widgets/fonts_dialog.dart';
import 'package:rich_editor/src/widgets/insert_image_dialog.dart';
import 'package:rich_editor/src/widgets/insert_link_dialog.dart';
import 'package:rich_editor/src/widgets/tab_button.dart';

import 'color_picker_dialog.dart';
import 'font_size_dialog.dart';
import 'heading_dialog.dart';

class EditorToolBar extends StatelessWidget {
  final Function(File image)? getImageUrl;
  final Function(File video)? getVideoUrl;
  final JavascriptExecutorBase javascriptExecutor;
  final bool? enableVideo;

  EditorToolBar({
    this.getImageUrl,
    this.getVideoUrl,
    required this.javascriptExecutor,
    this.enableVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    await javascriptExecutor.setBold();
                  },
                ),
                TabButton(
                  tooltip: 'Italic',
                  icon: Icons.format_italic,
                  onTap: () async {
                    await javascriptExecutor.setItalic();
                  },
                ),
                TabButton(
                  tooltip: 'Insert Link',
                  icon: Icons.link,
                  onTap: () async {
                    var link = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) {
                        return InsertLinkDialog();
                      },
                    );
                    if (link != null)
                      await javascriptExecutor.insertLink(link[0], link[1]);
                  },
                ),
                TabButton(
                  tooltip: 'Insert Image',
                  icon: Icons.image,
                  onTap: () async {
                    var link = await showDialog(
                      context: context,
                      builder: (_) {
                        return InsertImageDialog();
                      },
                    );
                    if (link != null) {
                      if (getImageUrl != null && link[2]) {
                        link[0] = await getImageUrl!(File(link[0]));
                      }
                      await javascriptExecutor.insertImage(
                        link[0],
                        alt: link[1],
                      );
                    }
                  },
                ),
                Visibility(
                  visible: enableVideo!,
                  child: TabButton(
                    tooltip: 'Insert video',
                    icon: Icons.video_call_sharp,
                    onTap: () async {
                      var link = await showDialog(
                        context: context,
                        builder: (_) {
                          return InsertImageDialog(isVideo: true);
                        },
                      );
                      if (link != null) {
                        if (getVideoUrl != null && link[2]) {
                          link[0] = await getVideoUrl!(File(link[0]));
                        }
                        await javascriptExecutor.insertVideo(
                          link[0],
                          fromDevice: link[2],
                        );
                      }
                    },
                  ),
                ),
                TabButton(
                  tooltip: 'Underline',
                  icon: Icons.format_underline,
                  onTap: () async {
                    await javascriptExecutor.setUnderline();
                  },
                ),
                TabButton(
                  tooltip: 'Strike through',
                  icon: Icons.format_strikethrough,
                  onTap: () async {
                    await javascriptExecutor.setStrikeThrough();
                  },
                ),
                TabButton(
                  tooltip: 'Superscript',
                  icon: Icons.superscript,
                  onTap: () async {
                    await javascriptExecutor.setSuperscript();
                  },
                ),
                TabButton(
                  tooltip: 'Subscript',
                  icon: Icons.subscript,
                  onTap: () async {
                    await javascriptExecutor.setSubscript();
                  },
                ),
                TabButton(
                  tooltip: 'Clear format',
                  icon: Icons.format_clear,
                  onTap: () async {
                    await javascriptExecutor.removeFormat();
                  },
                ),
                TabButton(
                  tooltip: 'Undo',
                  icon: Icons.undo,
                  onTap: () async {
                    await javascriptExecutor.undo();
                  },
                ),
                TabButton(
                  tooltip: 'Redo',
                  icon: Icons.redo,
                  onTap: () async {
                    await javascriptExecutor.redo();
                  },
                ),
                TabButton(
                  tooltip: 'Blockquote',
                  icon: Icons.format_quote,
                  onTap: () async {
                    await javascriptExecutor.setBlockQuote();
                  },
                ),
                TabButton(
                  tooltip: 'Font format',
                  icon: Icons.text_format,
                  onTap: () async {
                    var command = await showDialog(
                      // isScrollControlled: true,
                      context: context,
                      builder: (_) {
                        return HeadingDialog();
                      },
                    );
                    if (command != null) {
                      if (command == 'p') {
                        await javascriptExecutor.setFormattingToParagraph();
                      } else if (command == 'pre') {
                        await javascriptExecutor.setPreformat();
                      } else if (command == 'blockquote') {
                        await javascriptExecutor.setBlockQuote();
                      } else {
                        await javascriptExecutor
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
                      var command = await showDialog(
                        // isScrollControlled: true,
                        context: context,
                        builder: (_) {
                          return FontsDialog();
                        },
                      );
                      if (command != null)
                        await javascriptExecutor.setFontName(command);
                    },
                  ),
                ),
                TabButton(
                  icon: Icons.format_size,
                  tooltip: 'Font Size',
                  onTap: () async {
                    String? command = await showDialog(
                      // isScrollControlled: true,
                      context: context,
                      builder: (_) {
                        return FontSizeDialog();
                      },
                    );
                    if (command != null)
                      await javascriptExecutor
                          .setFontSize(int.tryParse(command)!);
                  },
                ),
                TabButton(
                  tooltip: 'Text Color',
                  icon: Icons.format_color_text,
                  onTap: () async {
                    var color = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ColorPickerDialog(color: Colors.blue);
                      },
                    );
                    if (color != null)
                      await javascriptExecutor.setTextColor(color);
                  },
                ),
                TabButton(
                  tooltip: 'Background Color',
                  icon: Icons.format_color_fill,
                  onTap: () async {
                    var color = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return ColorPickerDialog(color: Colors.blue);
                      },
                    );
                    if (color != null)
                      await javascriptExecutor.setTextBackgroundColor(color);
                  },
                ),
                TabButton(
                  tooltip: 'Increase Indent',
                  icon: Icons.format_indent_increase,
                  onTap: () async {
                    await javascriptExecutor.setIndent();
                  },
                ),
                TabButton(
                  tooltip: 'Decrease Indent',
                  icon: Icons.format_indent_decrease,
                  onTap: () async {
                    await javascriptExecutor.setOutdent();
                  },
                ),
                TabButton(
                  tooltip: 'Align Left',
                  icon: Icons.format_align_left_outlined,
                  onTap: () async {
                    await javascriptExecutor.setJustifyLeft();
                  },
                ),
                TabButton(
                  tooltip: 'Align Center',
                  icon: Icons.format_align_center,
                  onTap: () async {
                    await javascriptExecutor.setJustifyCenter();
                  },
                ),
                TabButton(
                  tooltip: 'Align Right',
                  icon: Icons.format_align_right,
                  onTap: () async {
                    await javascriptExecutor.setJustifyRight();
                  },
                ),
                TabButton(
                  tooltip: 'Justify',
                  icon: Icons.format_align_justify,
                  onTap: () async {
                    await javascriptExecutor.setJustifyFull();
                  },
                ),
                TabButton(
                  tooltip: 'Bullet List',
                  icon: Icons.format_list_bulleted,
                  onTap: () async {
                    await javascriptExecutor.insertBulletList();
                  },
                ),
                TabButton(
                  tooltip: 'Numbered List',
                  icon: Icons.format_list_numbered,
                  onTap: () async {
                    await javascriptExecutor.insertNumberedList();
                  },
                ),
                TabButton(
                  tooltip: 'Checkbox',
                  icon: Icons.check_box_outlined,
                  onTap: () async {
                    var text = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return CheckDialog();
                      },
                    );
                    if (text != null)
                      await javascriptExecutor.insertCheckbox(text);
                  },
                ),

                /// TODO: Implement Search feature
                // TabButton(
                //   tooltip: 'Search',
                //   icon: Icons.search,
                //   onTap: () async {
                //     // await javascriptExecutor.insertNumberedList();
                //   },
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
