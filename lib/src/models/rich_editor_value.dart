import 'package:flutter/foundation.dart';

/// Names of the editing commands whose state the editor reports.
///
/// These are the `document.execCommand` names the editor uses.
abstract final class EditorCommand {
  static const undo = 'undo';
  static const redo = 'redo';
  static const bold = 'bold';
  static const italic = 'italic';
  static const underline = 'underline';
  static const subscript = 'subscript';
  static const superscript = 'superscript';
  static const strikeThrough = 'strikeThrough';
  static const foreColor = 'foreColor';
  static const backColor = 'backColor';
  static const fontName = 'fontName';
  static const fontSize = 'fontSize';
  static const formatBlock = 'formatBlock';
  static const justifyLeft = 'justifyLeft';
  static const justifyCenter = 'justifyCenter';
  static const justifyRight = 'justifyRight';
  static const justifyFull = 'justifyFull';
  static const insertUnorderedList = 'insertUnorderedList';
  static const insertOrderedList = 'insertOrderedList';
}

/// State of one editing command at the current selection.
@immutable
class CommandState {
  const CommandState({
    this.enabled = false,
    this.active = false,
    this.value = '',
  });

  factory CommandState.fromJson(Map<String, Object?> json) {
    return CommandState(
      enabled: json['enabled'] == true,
      active: json['active'] == true,
      value: json['value']?.toString() ?? '',
    );
  }

  /// Whether the command can be run at the current selection.
  final bool enabled;

  /// Whether the formatting is applied at the current selection,
  /// e.g. the cursor is inside bold text.
  final bool active;

  /// The command's current value, e.g. `h2` for [EditorCommand.formatBlock]
  /// or `rgb(255, 0, 0)` for [EditorCommand.foreColor].
  final String value;

  @override
  bool operator ==(Object other) =>
      other is CommandState &&
      other.enabled == enabled &&
      other.active == active &&
      other.value == value;

  @override
  int get hashCode => Object.hash(enabled, active, value);

  @override
  String toString() =>
      'CommandState(enabled: $enabled, active: $active, value: $value)';
}

/// The editor's content and the formatting state at the cursor.
@immutable
class RichEditorValue {
  const RichEditorValue({
    this.html = '',
    this.didHtmlChange = false,
    this.commandStates = const {},
  });

  static const empty = RichEditorValue();

  /// The editor content. Empty when the editor holds no content.
  final String html;

  /// Whether [html] differs from the HTML the application last set.
  final bool didHtmlChange;

  /// Command states keyed by [EditorCommand] names.
  final Map<String, CommandState> commandStates;

  /// Whether [command] is applied at the cursor.
  bool isActive(String command) => commandStates[command]?.active ?? false;

  /// The value of [command] at the cursor, or an empty string.
  String valueOf(String command) => commandStates[command]?.value ?? '';

  RichEditorValue copyWith({
    String? html,
    bool? didHtmlChange,
    Map<String, CommandState>? commandStates,
  }) {
    return RichEditorValue(
      html: html ?? this.html,
      didHtmlChange: didHtmlChange ?? this.didHtmlChange,
      commandStates: commandStates ?? this.commandStates,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RichEditorValue &&
      other.html == html &&
      other.didHtmlChange == didHtmlChange &&
      mapEquals(other.commandStates, commandStates);

  @override
  int get hashCode => Object.hash(
        html,
        didHtmlChange,
        Object.hashAllUnordered(commandStates.entries
            .map((entry) => Object.hash(entry.key, entry.value))),
      );
}
