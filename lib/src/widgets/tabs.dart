import 'package:flutter/material.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
import 'package:rich_editor/src/widgets/insert_image_dialog.dart';
import 'package:rich_editor/src/widgets/insert_link_dialog.dart';
import 'package:rich_editor/src/widgets/tab_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GroupedTab extends StatelessWidget {
  final WebViewController? controller;

  GroupedTab({this.controller});

  JavascriptExecutorBase javascriptExecutorBase = JavascriptExecutorBase();

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      javascriptExecutorBase.init(controller!);
    }

    return Container(
      // color: Color(0xff424242),
      height: 59.0,
      child: Column(
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: [
                TabButton(
                  icon: Icons.format_bold,
                  onTap: () async {
                    await javascriptExecutorBase.setBold();
                  },
                ),
                TabButton(
                  icon: Icons.format_italic,
                  onTap: () async {
                    await javascriptExecutorBase.setItalic();
                  },
                ),
                TabButton(
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
                      await javascriptExecutorBase.insertLink(link[0], link[1]);
                  },
                ),
                TabButton(
                  icon: Icons.image,
                  onTap: () async {
                    var link = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) {
                        return InsertImageDialog();
                      },
                    );
                    if (link != null) {
                      await javascriptExecutorBase.insertImage(
                        link[0],
                        alt: link[1],
                      );
                    }
                  },
                ),
                TabButton(
                  icon: Icons.format_underline,
                  onTap: () async {
                    await javascriptExecutorBase.setUnderline();
                  },
                ),
                TabButton(
                  icon: Icons.format_strikethrough,
                  onTap: () async {
                    await javascriptExecutorBase.setStrikeThrough();
                  },
                ),
                TabButton(
                  icon: Icons.superscript,
                  onTap: () async {
                    await javascriptExecutorBase.setSuperscript();
                  },
                ),
                TabButton(
                  icon: Icons.subscript,
                  onTap: () async {
                    await javascriptExecutorBase.setSubscript();
                  },
                ),
                TabButton(
                  icon: Icons.format_clear,
                  onTap: () async {
                    await javascriptExecutorBase.removeFormat();
                  },
                ),
                TabButton(
                  icon: Icons.redo,
                  onTap: () async {
                    await javascriptExecutorBase.redo();
                  },
                ),
                TabButton(
                  icon: Icons.undo,
                  onTap: () async {
                    await javascriptExecutorBase.undo();
                  },
                ),

                TabButton(
                  icon: Icons.format_quote,
                  onTap: () async {
                    await javascriptExecutorBase.setBlockQuote();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
