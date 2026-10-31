import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rich_editor/src/controller/rich_editor_controller.dart';
import 'package:rich_editor/src/models/enum/bar_position.dart';
import 'package:rich_editor/src/models/rich_editor_options.dart';
import 'package:rich_editor/src/models/rich_editor_value.dart';
import 'package:rich_editor/src/services/local_server.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';
import 'package:rich_editor/src/widgets/editor_tool_bar.dart';

/// Builds a toolbar for [RichEditor]; see [RichEditor.toolbarBuilder].
typedef RichEditorToolbarBuilder = Widget Function(
    BuildContext context, RichEditorController controller);

class RichEditor extends StatefulWidget {
  /// Controls the editor and exposes its content; optional.
  final RichEditorController? controller;

  /// Initial HTML. Changing it replaces the editor content.
  final String? value;
  final RichEditorOptions editorOptions;
  final Future<String> Function(File image)? getImageUrl;
  final Future<String> Function(File video)? getVideoUrl;
  final bool disableVideo;
  final VoidCallback? onDisabledVideoTap;

  /// Called with the new HTML whenever the user changes the content.
  final ValueChanged<String>? onChanged;

  /// Called when [getImageUrl] or [getVideoUrl] throws. Defaults to
  /// reporting the error with [FlutterError.reportError].
  final void Function(Object error, StackTrace stackTrace)? onUploadError;

  /// Replaces the built-in toolbar, which is placed at
  /// [RichEditorOptions.barPosition]. Ignored for [BarPosition.custom].
  final RichEditorToolbarBuilder? toolbarBuilder;

  const RichEditor({
    super.key,
    this.controller,
    this.value,
    this.editorOptions = const RichEditorOptions(),
    this.getImageUrl,
    this.getVideoUrl,
    this.disableVideo = false,
    this.onDisabledVideoTap,
    this.onChanged,
    this.onUploadError,
    this.toolbarBuilder,
  });

  @override
  RichEditorState createState() => RichEditorState();
}

class RichEditorState extends State<RichEditor> {
  static const _assetPath = 'packages/rich_editor/assets/editor/editor.html';

  InAppWebViewController? _webViewController;
  RichEditorController? _internalController;
  LocalServer? _localServer;
  bool _isWebViewLoaded = false;
  bool _isInitializing = false;
  bool _isUploadingMedia = false;

  /// The controller in use: [RichEditor.controller] or an internal one.
  RichEditorController get controller =>
      widget.controller ?? (_internalController ??= RichEditorController());

  JavascriptExecutorBase get javascriptExecutor => controller.executor;

  // Android loads the editor from its APK assets; elsewhere it is served
  // over http://localhost, which gives embedded videos a proper origin.
  bool get _usesLocalServer => !Platform.isAndroid;

  @override
  void initState() {
    super.initState();
    if (_usesLocalServer) {
      _localServer = LocalServer();
      _localServer!.start().ignore(); // a failure surfaces when loading
    }
  }

  @override
  void didUpdateWidget(RichEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldController = oldWidget.controller ?? _internalController;
    if (widget.controller != oldWidget.controller &&
        oldController != controller) {
      oldController?.detach();
      if (oldWidget.controller == null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _isWebViewLoaded = false;
      _initializeEditor();
    }

    if (!_isWebViewLoaded) return;

    final value = widget.value;
    if (value != oldWidget.value && value != controller.html) {
      controller.setHtml(value ?? '');
    }
    if (widget.editorOptions != oldWidget.editorOptions) {
      _applyOptions(oldWidget.editorOptions);
    }
  }

  @override
  void dispose() {
    controller.detach();
    _internalController?.dispose();
    _webViewController = null;
    _localServer?.close();
    super.dispose();
  }

  Future<void> _loadEditor(InAppWebViewController webViewController) async {
    final WebUri url;
    if (_usesLocalServer) {
      try {
        final port = await _localServer!.start();
        url = WebUri('http://localhost:$port/$_assetPath');
      } catch (e, s) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: e,
          stack: s,
          library: 'rich_editor',
          context: ErrorDescription('while starting the editor server'),
        ));
        return;
      }
    } else {
      url = WebUri('file:///android_asset/flutter_assets/$_assetPath');
    }
    if (!mounted) return;
    await webViewController.loadUrl(urlRequest: URLRequest(url: url));
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.editorOptions;
    final toolbar = options.barPosition == BarPosition.custom
        ? null
        : widget.toolbarBuilder?.call(context, controller) ?? _buildToolBar();

    return Stack(
      children: [
        Column(
          children: [
            if (options.barPosition == BarPosition.top) toolbar!,
            Expanded(
              child: InAppWebView(
                initialSettings: InAppWebViewSettings(
                  mixedContentMode:
                      MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
                  allowsInlineMediaPlayback: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsBackForwardNavigationGestures: false,
                  allowsLinkPreview: false,
                  isFraudulentWebsiteWarningEnabled: false,
                  disallowOverScroll: true,
                ),
                onWebViewCreated: (webViewController) async {
                  _webViewController = webViewController;
                  webViewController.addJavaScriptHandler(
                    handlerName: 'editorReady',
                    callback: (_) => _initializeEditor(),
                  );
                  webViewController.addJavaScriptHandler(
                    handlerName: 'editorStateChanged',
                    callback: _handleEditorStateChanged,
                  );
                  await _loadEditor(webViewController);
                },
                onLoadStop: (_, __) => _initializeEditor(),
                // Let the editor scroll vertically inside scrollable parents.
                gestureRecognizers: {
                  Factory(() => VerticalDragGestureRecognizer()),
                },
                onReceivedError: (_, request, error) {
                  if (request.isForMainFrame ?? true) {
                    debugPrint('rich_editor failed to load: $error');
                  }
                },
                onConsoleMessage: kDebugMode
                    ? (_, message) => debugPrint('rich_editor: $message')
                    : null,
              ),
            ),
            if (options.barPosition == BarPosition.bottom) toolbar!,
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    options.labels.uploading,
                    style: const TextStyle(
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

  Widget _buildToolBar() {
    final options = widget.editorOptions;
    return ValueListenableBuilder<RichEditorValue>(
      valueListenable: controller,
      builder: (context, value, _) => EditorToolBar(
        getImageUrl: widget.getImageUrl != null ? uploadImageWithLoader : null,
        getVideoUrl: widget.getVideoUrl != null ? uploadVideoWithLoader : null,
        javascriptExecutor: javascriptExecutor,
        enableVideo: options.enableVideo,
        disableVideo: widget.disableVideo,
        onDisabledVideoTap: widget.onDisabledVideoTap,
        isWebViewLoaded: _isWebViewLoaded,
        items: options.toolbarItems,
        height: options.toolbarHeight,
        labels: options.labels,
        commandStates: value.commandStates,
        onUploadError: _reportUploadError,
      ),
    );
  }

  void _reportUploadError(Object error, StackTrace stackTrace) {
    final onUploadError = widget.onUploadError;
    if (onUploadError != null) {
      onUploadError(error, stackTrace);
      return;
    }
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'rich_editor',
      context: ErrorDescription('while uploading media'),
    ));
  }

  /// Applies the editor options that differ from [old], or all of them.
  Future<void> _applyOptions([RichEditorOptions? old]) async {
    final options = widget.editorOptions;
    final executor = javascriptExecutor;
    final background = options.backgroundColor;
    final textColor = options.baseTextColor;
    final padding = options.padding;
    final fontFamily = options.baseFontFamily;

    if (padding != null && padding != old?.padding) {
      await executor.setPadding(padding);
    }
    if (background != null && background != old?.backgroundColor) {
      await executor.setBackgroundColor(background);
    }
    if (textColor != null && textColor != old?.baseTextColor) {
      await executor.setBaseTextColor(textColor);
    }
    if (old == null || options.placeholder != old.placeholder) {
      await executor.setPlaceholder(options.placeholder ?? '');
    }
    if (fontFamily != null && fontFamily != old?.baseFontFamily) {
      await executor.setBaseFontFamily(fontFamily);
    }
  }

  /// Hooks the editor page up to [controller]. Safe to call repeatedly:
  /// both the page and the WebView report when loading finished.
  Future<void> _initializeEditor() async {
    final webViewController = _webViewController;
    if (_isWebViewLoaded || _isInitializing || webViewController == null) {
      return;
    }
    _isInitializing = true;
    try {
      final controller = this.controller;
      controller.executor.init(webViewController);
      final pendingHtml = controller.markReady();
      final html = pendingHtml ?? widget.value;
      if (html != null) await controller.executor.setHtml(html);
      await _applyOptions();
      if (mounted) setState(() => _isWebViewLoaded = true);
    } finally {
      _isInitializing = false;
    }
  }

  void _handleEditorStateChanged(List<dynamic> arguments) {
    final data = arguments.isEmpty ? null : arguments.first;
    if (data is! Map) return;

    final html = data['html'];
    final states = data['commandStates'];
    final previousHtml = controller.html;
    controller.value = controller.value.copyWith(
      html: html is String ? html : null,
      didHtmlChange: data['didHtmlChange'] == true,
      commandStates: states is Map
          ? {
              for (final entry in states.entries)
                if (entry.value is Map)
                  entry.key.toString(): CommandState.fromJson(
                      Map<String, Object?>.from(entry.value as Map)),
            }
          : null,
    );

    if (html is String &&
        html != previousHtml &&
        data['fromApplication'] != true) {
      widget.onChanged?.call(html);
    }
  }

  /// Get current HTML from editor
  Future<String?> getHtml() => controller.getHtml();

  /// Set your HTML to the editor
  Future<void> setHtml(String html) => controller.setHtml(html);

  /// Hide the keyboard using JavaScript since it's being opened in a WebView
  /// https://stackoverflow.com/a/8263376/10835183
  Future<void> unFocus() => controller.unFocus();

  /// Clear editor content using Javascript
  Future<void> clear() => controller.clear();

  /// Focus and Show the keyboard using JavaScript
  /// https://stackoverflow.com/a/6809236/10835183
  Future<void> focus() => controller.focus();

  /// Add custom CSS code to Editor
  Future<void> loadCSS(String cssFile) => javascriptExecutor.loadCSS(cssFile);

  /// Whether the editor holds no text and no media.
  Future<bool> isEmpty() => controller.isEmpty();

  /// Enable Editing (If editing is disabled)
  Future<void> enableEditing() => controller.enableEditing();

  /// Disable Editing (Could be used for a 'view mode')
  Future<void> disableEditing() => controller.disableEditing();

  /// Upload image with loading state
  Future<String> uploadImageWithLoader(File image) =>
      _uploadWithLoader(() => widget.getImageUrl!(image));

  /// Upload video with loading state
  Future<String> uploadVideoWithLoader(File video) =>
      _uploadWithLoader(() => widget.getVideoUrl!(video));

  Future<String> _uploadWithLoader(Future<String> Function() upload) async {
    setState(() => _isUploadingMedia = true);
    try {
      return await upload();
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }
}
