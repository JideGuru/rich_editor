import 'package:flutter/foundation.dart';
import 'package:rich_editor/src/models/rich_editor_value.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';

/// Controls a [RichEditor] and exposes its content and formatting state.
///
/// The [value] updates as the user edits, so the controller can be listened
/// to (e.g. with a [ValueListenableBuilder]) to build custom toolbars that
/// highlight active formatting. Formatting commands are on [executor].
class RichEditorController extends ValueNotifier<RichEditorValue> {
  RichEditorController() : super(RichEditorValue.empty);

  /// Runs editing commands, e.g. `controller.executor.setBold()`.
  final JavascriptExecutorBase executor = JavascriptExecutorBase();

  final ValueNotifier<bool> _ready = ValueNotifier(false);

  /// HTML or a JSON document set before the editor was ready.
  Object? _pendingContent;

  /// Whether the editor finished loading and accepts commands.
  ValueListenable<bool> get ready => _ready;

  /// The current editor HTML, as last reported by the editor.
  String get html => value.html;

  /// Replaces the editor content.
  ///
  /// Can be called before the editor finished loading; the content is
  /// applied once it is ready.
  Future<void> setHtml(String html) async {
    if (!_ready.value) {
      _pendingContent = html;
      return;
    }
    await executor.setHtml(html);
  }

  /// Reads the current HTML from the editor.
  Future<String> getHtml() => executor.getCurrentHtml();

  /// Replaces the editor content with a Tiptap (ProseMirror) JSON document,
  /// as [getJson] returns it.
  ///
  /// Returns false, leaving the content as it was, when [json] doesn't fit
  /// the editor. Before the editor finished loading, the document is applied
  /// once it is ready, and this returns true.
  Future<bool> setJson(Map<String, dynamic> json) async {
    if (!_ready.value) {
      _pendingContent = json;
      return true;
    }
    return executor.setJson(json);
  }

  /// Reads the content as a Tiptap (ProseMirror) JSON document, e.g. to
  /// store it or to render it without a WebView.
  Future<Map<String, dynamic>> getJson() => executor.getJson();

  /// The content as plain text, paragraphs and line breaks as new lines.
  Future<String> getText() => executor.getText();

  Future<void> clear() => setHtml('');

  Future<bool> isEmpty() => executor.isEmpty();

  Future<void> focus() => executor.focus();

  Future<void> unFocus() => executor.unFocus();

  Future<void> enableEditing() => executor.setInputEnabled(true);

  Future<void> disableEditing() => executor.setInputEnabled(false);

  /// Called by the editor once it is loaded. Returns the content set before
  /// then: an HTML [String] or a JSON document [Map].
  @internal
  Object? markReady() {
    _ready.value = true;
    final content = _pendingContent;
    _pendingContent = null;
    return content;
  }

  /// Called by the editor when it is disposed or switches controllers.
  @internal
  void detach() {
    executor.init(null);
    _ready.value = false;
  }

  @override
  void dispose() {
    _ready.dispose();
    super.dispose();
  }
}
