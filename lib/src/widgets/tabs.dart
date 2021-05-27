import 'package:flutter/material.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
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
                    if(link != null)
                      await javascriptExecutorBase.insertLink(link[0], link[1]);
                  },
                ),
                TabButton(
                  icon: Icons.image,
                  onTap: () async {
                    await javascriptExecutorBase.insertImage(
                      'https://avatars.githubusercontent.com/u/24323581?v=4'
                    );
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
