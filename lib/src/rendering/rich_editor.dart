import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rich_editor/src/services/local_server.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
import 'package:rich_editor/src/widgets/editor_tool_bar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RichEditor extends StatefulWidget {
  final String? value;
  final Color? backgroundColor;
  final Color? baseTextColor;
  final EdgeInsets? padding;
  final String? placeholder;
  final String? baseFontFamily;
  final Function(File image)? getImageUrl;
  final Function(File video)? getVideoUrl;

  RichEditor({
    Key? key,
    this.value,
    this.backgroundColor,
    this.baseTextColor,
    this.padding,
    this.placeholder,
    this.baseFontFamily,
    this.getImageUrl,
    this.getVideoUrl,
  }) : super(key: key);

  @override
  RichEditorState createState() => RichEditorState();
}

class RichEditorState extends State<RichEditor> {
  WebViewController? _controller;
  final Key _mapKey = UniqueKey();
  String assetPath = 'packages/rich_editor/assets/editor/editor.html';

  int port = 5321;
  String html = '';
  LocalServer? localServer;
  JavascriptExecutorBase javascriptExecutor = JavascriptExecutorBase();

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    if (!Platform.isAndroid) {
      _initServer();
    }
  }

  _initServer() async {
    localServer = LocalServer(port);
    await localServer!.start(_handleRequest);
  }

  void _handleRequest(HttpRequest request) {
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
        EditorToolBar(
          controller: _controller,
          getImageUrl: widget.getImageUrl,
          javascriptExecutor: javascriptExecutor,
        ),
        Expanded(
          child: WebView(
            key: _mapKey,
            onWebViewCreated: (WebViewController controller) async {
              _controller = controller;
              setState(() {});
              if (!Platform.isAndroid) {
                await _loadHtmlFromAssets();
              } else {
                await _controller!
                    .loadUrl('file:///android_asset/flutter_assets/$assetPath');
              }
              javascriptExecutor.init(_controller!);
            },
            onPageFinished: (link) async {
              await _setInitialValues();
            },
            javascriptMode: JavascriptMode.unrestricted,
            gestureNavigationEnabled: true,
            gestureRecognizers: [
              Factory(() => VerticalDragGestureRecognizer()..onUpdate = (_) {}),
            ].toSet(),
            onWebResourceError: (e) {
              print("error ${e.description}");
            },
          ),
        )
      ],
    );
  }

  _setInitialValues() async {
    if (widget.value != null) await javascriptExecutor.setHtml(widget.value!);
    if (widget.padding != null)
      await javascriptExecutor.setPadding(widget.padding!);
    if (widget.backgroundColor != null)
      await javascriptExecutor.setBackgroundColor(widget.backgroundColor!);
    if (widget.baseTextColor != null)
      await javascriptExecutor.setBaseTextColor(widget.baseTextColor!);
    if (widget.placeholder != null)
      await javascriptExecutor.setPlaceholder(widget.placeholder!);
    if (widget.baseFontFamily != null)
      await javascriptExecutor.setBaseFontFamily(widget.baseFontFamily!);
  }

  /// Get current HTML from editor
  Future<String?> getHtml() async {
    try {
      html = await javascriptExecutor.getCurrentHtml();
    } catch (e) {}
    return html;
  }

  /// Set your HTML to the editor
  setHtml(String html) async {
    return await javascriptExecutor.setHtml(html);
  }

  /// Hide the keyboard using JavaScript since it's being opened in a WebView
  /// https://stackoverflow.com/a/8263376/10835183
  unFocus() {
    javascriptExecutor.unFocus();
  }

  /// Clear editor content using Javascript
  clear() {
    _controller!.evaluateJavascript(
        'document.getElementById(\'editor\').innerHTML = "";');
  }

  /// Focus and Show the keyboard using JavaScript
  /// https://stackoverflow.com/a/6809236/10835183
  focus() {
    javascriptExecutor.focus();
  }

  /// Add custom CSS code to Editor
  loadCSS(String cssFile) {
    var jsCSSImport = "(function() {" +
        "    var head  = document.getElementsByTagName(\"head\")[0];" +
        "    var link  = document.createElement(\"link\");" +
        "    link.rel  = \"stylesheet\";" +
        "    link.type = \"text/css\";" +
        "    link.href = \"" +
        cssFile +
        "\";" +
        "    link.media = \"all\";" +
        "    head.appendChild(link);" +
        "}) ();";
    _controller!.evaluateJavascript(jsCSSImport);
  }

  /// if html is equal to html RichTextEditor sets by default at start
  /// (<p>​</p>) so that RichTextEditor can be considered as 'empty'.
  Future<bool> isEmpty() async {
    html = await javascriptExecutor.getCurrentHtml();
    return html == '<p>​</p>';
  }
}
