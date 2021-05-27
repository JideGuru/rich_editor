import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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
  String assetPath = 'packages/rich_editor/assets/editor/editor.html';

  int port = 5321;
  LocalServer? localServer;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    if (!Platform.isAndroid) {
      initServer();
    }
  }

  initServer() {
    localServer = LocalServer(port);
    localServer!.start(handleRequest);
  }

  void handleRequest(HttpRequest request) {
    try {
      if (request.method == 'GET' &&
          request.uri.queryParameters['query'] == "getRawTeXHTML") {
      } else {}
    } catch (e) {
      print('Exception in handleRequest: $e');
    }
  }


  @override
  void dispose() {
    if (_controller != null) {
      _controller = null;
    }
    if (!Platform.isAndroid) {
      localServer!.close();
    }
    super.dispose();
  }

  _loadHtmlFromAssets() async {
    final filePath = assetPath;
    _controller!.loadUrl("http://localhost:$port/$filePath");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GroupedTab(controller: _controller),
        Expanded(
          child: WebView(
            key: _mapKey,
            // initialUrl:
            //     'file:///android_asset/flutter_assets/packages/rich_editor/assets/editor/editor.html',
            onWebViewCreated: (WebViewController controller) {
              _controller = controller;
              print('WebView created');
              setState(() {});
              if (!Platform.isAndroid) {
                print('Loading');
                _loadHtmlFromAssets();
              } else {
                _controller!.loadUrl('file:///android_asset/flutter_assets/$assetPath');
              }
            },
            javascriptMode: JavascriptMode.unrestricted,
            gestureNavigationEnabled: true,
            gestureRecognizers: [
              Factory(
                      () => VerticalDragGestureRecognizer()..onUpdate = (_) {}),
            ].toSet(),
            onWebResourceError: (e) {
              print("error ${e.description}");
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
