import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/button.dart';
import 'package:rich_editor/src/utils/constants.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
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
      color: Color(0xff424242),
      height: 59.0,
      child: Column(
        children: [
          Flexible(
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: [
                for(Button button in buttons)
                  TabButton(
                    icon: button.icon,
                    onTap: () async {
                      print('BOLDDD');
                      javascriptExecutorBase.setBold();
                      String? html = await javascriptExecutorBase.getHtml();
                      print(html!);
                    },
                  )
                // TabButton(
                //   icon: Icons.link,
                //   onTap: () async {
                //     javascriptExecutorBase.insertLink(
                //         'https://github.com/JideGuru/rich_editor', 'git');
                //   },
                // ),
                // TabButton(
                //   icon: Icons.format_bold,
                //   onTap: () async {
                //     javascriptExecutorBase.setBold();
                //   },
                // )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
