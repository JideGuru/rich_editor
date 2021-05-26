import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rich_editor/src/services/local_server.dart';
import 'package:rich_editor/src/widgets/tabs.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RichEditor extends StatefulWidget {
  @override
  _RichEditorState createState() => _RichEditorState();
}

class _RichEditorState extends State<RichEditor> {
  WebViewController? _controller;
  String text = "";
  final Key _mapKey = UniqueKey();

  int port = 5321;
  LocalServer? localServer;
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GroupedTab(),
        Flexible(
          child: WebView(
            initialUrl: 'file:///android_asset/flutter_assets/packages/rich_editor/assets/editor/editor.html',
            onWebViewCreated: (WebViewController controller) {
              _controller = _controller;
              setState(() {});
            },
          ),
          // child: InAppWebView(
          //   initialFile: 'packages/rich_editor/assets/editor/index.html',
          // ),
        )
      ],
    );
  }
}
