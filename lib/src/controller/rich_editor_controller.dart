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
  String? _pendingHtml;

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
      _pendingHtml = html;
      return;
    }
    await executor.setHtml(html);
  }

  /// Reads the current HTML from the editor.
  Future<String> getHtml() => executor.getCurrentHtml();

  Future<void> clear() => setHtml('');

  Future<bool> isEmpty() => executor.isEmpty();

  Future<void> focus() => executor.focus();

  Future<void> unFocus() => executor.unFocus();

  Future<void> enableEditing() => executor.setInputEnabled(true);

  Future<void> disableEditing() => executor.setInputEnabled(false);

  /// Called by the editor once it is loaded. Returns HTML set before then.
  @internal
  String? markReady() {
    _ready.value = true;
    final html = _pendingHtml;
    _pendingHtml = null;
    return html;
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
