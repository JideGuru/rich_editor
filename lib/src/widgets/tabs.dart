import 'package:flutter/material.dart';
import 'package:rich_editor/src/utils/constants.dart';
import 'package:rich_editor/src/models/button.dart';
import 'package:rich_editor/src/widgets/tab_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GroupedTab extends StatelessWidget {
  final WebViewController? controller;

  GroupedTab({this.controller});

  @override
  Widget build(BuildContext context) {
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
                      // await controller?.evaluateJavascript('editor.undo()');
                      await controller?.evaluateJavascript('editor.setBold()');
                      String? html = await controller?.evaluateJavascript('editor.getEncodedHtml()');
                      print(Uri.decodeFull(html!));
                    },
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
