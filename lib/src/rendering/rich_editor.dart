import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rich_editor/src/models/enum/bar_position.dart';
import 'package:rich_editor/src/models/rich_editor_options.dart';
import 'package:rich_editor/src/services/local_server.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
import 'package:rich_editor/src/widgets/editor_tool_bar.dart';

class RichEditor extends StatefulWidget {
  final String? value;
  final RichEditorOptions? editorOptions;
  final Future<String> Function(File image)? getImageUrl;
  final Future<String> Function(File video)? getVideoUrl;
  final bool? disableVideo;
  final VoidCallback? onDisabledVideoTap;

  const RichEditor({
    super.key,
    this.value,
    this.editorOptions,
    this.getImageUrl,
    this.getVideoUrl,
    this.disableVideo = false,
    this.onDisabledVideoTap,
  });

  @override
  RichEditorState createState() => RichEditorState();
}

class RichEditorState extends State<RichEditor> {
  InAppWebViewController? _controller;
  final Key _mapKey = UniqueKey();
  String assetPath = 'packages/rich_editor/assets/editor/editor.html';

  int port = 5321;
  String html = '';
  LocalServer? localServer;
  JavascriptExecutorBase javascriptExecutor = JavascriptExecutorBase();
  bool _isWebViewLoaded = false;
  Timer? _loadTimeout;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isIOS) {
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
      debugPrint('Exception in handleRequest: $e');
    }
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    if (_controller != null) {
      _controller = null;
    }
    if (!kIsWeb && !Platform.isAndroid) {
      localServer!.close();
    }
    super.dispose();
  }

  _loadHtmlFromAssets() async {
    final filePath = assetPath;
    _controller!.loadUrl(
      urlRequest: URLRequest(
        url: WebUri.uri(Uri.tryParse('http://localhost:$port/$filePath')!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Visibility(
              visible: widget.editorOptions!.barPosition == BarPosition.top,
              child: _buildToolBar(),
            ),
            Expanded(
              child: InAppWebView(
                key: _mapKey,
                onWebViewCreated: (controller) async {
                  _controller = controller;
                  setState(() {});

                  // Set a timeout fallback to ensure editor loads even if onLoadStop doesn't fire properly
                  _loadTimeout = Timer(const Duration(seconds: 3), () {
                    if (!_isWebViewLoaded && _controller != null) {
                      debugPrint(
                          'WebView load timeout - forcing initialization');
                      _forceInitialization();
                    }
                  });

                  if (!kIsWeb && !Platform.isAndroid) {
                    await _loadHtmlFromAssets();
                  } else {
                    await _controller!.loadUrl(
                      urlRequest: URLRequest(
                        url: WebUri.uri(
                          Uri.tryParse(
                              'file:///android_asset/flutter_assets/$assetPath')!,
                        ),
                      ),
                    );
                  }
                },
                onLoadStop: (controller, link) async {
                  debugPrint('WebView onLoadStop: ${link?.toString()}');
                  _handleWebViewLoaded();
                },
                // javascriptMode: JavascriptMode.unrestricted,
                // gestureNavigationEnabled: false,
                gestureRecognizers: {
                  Factory(
                      () => VerticalDragGestureRecognizer()..onUpdate = (_) {}),
                },
                onReceivedError: (controller, url, e) {
                  debugPrint('WebView error: $e');
                },
                onConsoleMessage: (controller, consoleMessage) async {
                  debugPrint('WebView Message: $consoleMessage');
                },
              ),
            ),
            Visibility(
              visible: widget.editorOptions!.barPosition == BarPosition.bottom,
              child: _buildToolBar(),
            ),
          ],
        ),
        // Media upload loading overlay
        if (_isUploadingMedia)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Uploading...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  _buildToolBar() {
    return EditorToolBar(
      getImageUrl: widget.getImageUrl != null ? uploadImageWithLoader : null,
      getVideoUrl: widget.getVideoUrl != null ? uploadVideoWithLoader : null,
      javascriptExecutor: javascriptExecutor,
      enableVideo: widget.editorOptions!.enableVideo,
      disableVideo: widget.disableVideo,
      onDisabledVideoTap: widget.onDisabledVideoTap,
      isWebViewLoaded: _isWebViewLoaded,
    );
  }

  _setInitialValues() async {
    if (widget.value != null) await javascriptExecutor.setHtml(widget.value!);
    if (widget.editorOptions!.padding != null) {
      await javascriptExecutor.setPadding(widget.editorOptions!.padding!);
    }
    if (widget.editorOptions!.backgroundColor != null) {
      await javascriptExecutor
          .setBackgroundColor(widget.editorOptions!.backgroundColor!);
    }
    if (widget.editorOptions!.baseTextColor != null) {
      await javascriptExecutor
          .setBaseTextColor(widget.editorOptions!.baseTextColor!);
    }
    if (widget.editorOptions!.placeholder != null) {
      await javascriptExecutor
          .setPlaceholder(widget.editorOptions!.placeholder!);
    }
    if (widget.editorOptions!.baseFontFamily != null) {
      await javascriptExecutor
          .setBaseFontFamily(widget.editorOptions!.baseFontFamily!);
    }
  }

  _addJSListener() async {
    _controller!.addJavaScriptHandler(
        handlerName: 'editor-state-changed-callback://',
        callback: (c) {
          debugPrint('Editor state changed callback: $c');
        });
  }

  /// Handle WebView loaded - simplified to always initialize
  _handleWebViewLoaded() async {
    if (!_isWebViewLoaded && _controller != null) {
      _loadTimeout?.cancel(); // Cancel timeout since we're loading now
      javascriptExecutor.init(_controller!);
      await _setInitialValues();
      _addJSListener();
      setState(() {
        _isWebViewLoaded = true;
      });
    }
  }

  /// Force initialization as fallback when timeout occurs
  _forceInitialization() async {
    if (!_isWebViewLoaded && _controller != null) {
      debugPrint('Force initialization triggered');
      await _handleWebViewLoaded();
    }
  }

  /// Get current HTML from editor
  Future<String?> getHtml() async {
    try {
      html = await javascriptExecutor.getCurrentHtml();
    } catch (e) {
      debugPrint('Exception in getHtml: $e');
    }
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
        source: 'document.getElementById(\'editor\').innerHTML = "";');
  }

  /// Focus and Show the keyboard using JavaScript
  /// https://stackoverflow.com/a/6809236/10835183
  focus() {
    javascriptExecutor.focus();
  }

  /// Add custom CSS code to Editor
  loadCSS(String cssFile) {
    var jsCSSImport =
        "(function() {    var head  = document.getElementsByTagName(\"head\")[0];    var link  = document.createElement(\"link\");    link.rel  = \"stylesheet\";    link.type = \"text/css\";    link.href = \"$cssFile\";    link.media = \"all\";    head.appendChild(link);}) ();";
    _controller!.evaluateJavascript(source: jsCSSImport);
  }

  /// if html is equal to html RichTextEditor sets by default at start
  /// (<p>​</p>) so that RichTextEditor can be considered as 'empty'.
  Future<bool> isEmpty() async {
    html = await javascriptExecutor.getCurrentHtml();
    return html == '<p>​</p>';
  }

  /// Enable Editing (If editing is disabled)
  enableEditing() async {
    await javascriptExecutor.setInputEnabled(true);
  }

  /// Disable Editing (Could be used for a 'view mode')
  disableEditing() async {
    await javascriptExecutor.setInputEnabled(false);
  }

  /// Upload image with loading state
  Future<String> uploadImageWithLoader(File image) async {
    setState(() {
      _isUploadingMedia = true;
    });
    try {
      final result = await widget.getImageUrl!(image);
      return result;
    } finally {
      setState(() {
        _isUploadingMedia = false;
      });
    }
  }

  /// Upload video with loading state
  Future<String> uploadVideoWithLoader(File video) async {
    setState(() {
      _isUploadingMedia = true;
    });
    try {
      final result = await widget.getVideoUrl!(video);
      return result;
    } finally {
      setState(() {
        _isUploadingMedia = false;
      });
    }
  }
}
