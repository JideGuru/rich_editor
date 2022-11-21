import 'dart:async';
import 'dart:html' as html;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rich_editor/src/models/enum/bar_position.dart';
import 'package:rich_editor/src/models/rich_editor_options.dart';
import 'package:rich_editor/src/rendering/widgets/editor_tool_bar.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
import 'package:webview_flutter_web/webview_flutter_web.dart';

class RichEditor extends StatefulWidget {
  final String? value;
  final RichEditorOptions? editorOptions;
  final Function(File image)? getImageUrl;
  final Function(File video)? getVideoUrl;

  RichEditor({
    Key? key,
    this.value,
    this.editorOptions,
    this.getImageUrl,
    this.getVideoUrl,
  }) : super(key: key);

  @override
  RichEditorState createState() => RichEditorState();
}

class RichEditorState extends State<RichEditor> {
  InAppWebViewController? _controller;
  final Key _mapKey = UniqueKey();
  String assetPath = 'packages/rich_editor/assets/editor/editor.html';
  String webViewId = 'webEditor';
  int port = 5321;
  String htmlString = '';
  JavascriptExecutorBase javascriptExecutor = JavascriptExecutorBase();
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    WebView.platform = WebWebViewPlatform();
    loadEditorOnWeb();
  }

  loadEditorOnWeb() async {
    var htmlBody = await rootBundle.loadString(assetPath);
    final iframe = html.IFrameElement()
      ..srcdoc = htmlBody
      ..style.border = 'none' ..height = '400';
    ui.platformViewRegistry
        .registerViewFactory(webViewId, (int viewId) => iframe);
    loaded = true;
    setState(() {});
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller = null;
    }
    super.dispose();
  }

  _loadHtmlFromAssets() async {
    final filePath = assetPath;
    _controller!.loadUrl(
      urlRequest: URLRequest(
        url: Uri.tryParse('http://localhost:$port/$filePath'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Visibility(
          visible: widget.editorOptions!.barPosition == BarPosition.TOP,
          child: _buildToolBar(),
        ),
        Expanded(
          child: loaded ? HtmlElementView(viewType: webViewId) : SizedBox(),
        ),
        Visibility(
          visible: widget.editorOptions!.barPosition == BarPosition.BOTTOM,
          child: _buildToolBar(),
        ),
      ],
    );
  }

  _buildToolBar() {
    return EditorToolBar(
      getImageUrl: widget.getImageUrl,
      getVideoUrl: widget.getVideoUrl,
      javascriptExecutor: javascriptExecutor,
      enableVideo: widget.editorOptions!.enableVideo,
    );
  }

  _setInitialValues() async {
    if (widget.value != null) await javascriptExecutor.setHtml(widget.value!);
    if (widget.editorOptions!.padding != null)
      await javascriptExecutor.setPadding(widget.editorOptions!.padding!);
    if (widget.editorOptions!.backgroundColor != null)
      await javascriptExecutor
          .setBackgroundColor(widget.editorOptions!.backgroundColor!);
    if (widget.editorOptions!.baseTextColor != null)
      await javascriptExecutor
          .setBaseTextColor(widget.editorOptions!.baseTextColor!);
    if (widget.editorOptions!.placeholder != null)
      await javascriptExecutor
          .setPlaceholder(widget.editorOptions!.placeholder!);
    if (widget.editorOptions!.baseFontFamily != null)
      await javascriptExecutor
          .setBaseFontFamily(widget.editorOptions!.baseFontFamily!);
  }

  _addJSListener() async {
    _controller!.addJavaScriptHandler(
        handlerName: 'editor-state-changed-callback://',
        callback: (c) {
          print('Callback $c');
        });
  }

  /// Get current HTML from editor
  Future<String?> getHtml() async {
    try {
      htmlString = await javascriptExecutor.getCurrentHtml();
    } catch (e) {}
    return htmlString;
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
        source: 'document.getElementById(\'editor\').innerHTML = "";');
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
    _controller!.evaluateJavascript(source: jsCSSImport);
  }

  /// if html is equal to html RichTextEditor sets by default at start
  /// (<p>​</p>) so that RichTextEditor can be considered as 'empty'.
  Future<bool> isEmpty() async {
    htmlString = await javascriptExecutor.getCurrentHtml();
    return htmlString == '<p>​</p>';
  }

  /// Enable Editing (If editing is disabled)
  enableEditing() async {
    await javascriptExecutor.setInputEnabled(true);
  }

  /// Disable Editing (Could be used for a 'view mode')
  disableEditing() async {
    await javascriptExecutor.setInputEnabled(false);
  }
}
