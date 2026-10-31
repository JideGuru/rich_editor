import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'enum/bar_position.dart';
import 'rich_editor_labels.dart';
import 'toolbar_item.dart';

@immutable
class RichEditorOptions {
  final Color? backgroundColor;
  final Color? baseTextColor;
  final EdgeInsets? padding;

  /// Hint shown while the editor is empty.
  final String? placeholder;
  final String? baseFontFamily;
  final BarPosition barPosition;
  final bool enableVideo;

  /// Buttons of the built-in toolbar, in display order.
  final List<ToolbarItem> toolbarItems;
  final double toolbarHeight;
  final RichEditorLabels labels;

  const RichEditorOptions({
    this.backgroundColor,
    this.baseTextColor,
    this.padding,
    this.placeholder,
    this.baseFontFamily,
    this.barPosition = BarPosition.top,
    this.enableVideo = true,
    this.toolbarItems = ToolbarItem.values,
    this.toolbarHeight = 54.0,
    this.labels = const RichEditorLabels(),
  });

  @override
  bool operator ==(Object other) =>
      other is RichEditorOptions &&
      other.backgroundColor == backgroundColor &&
      other.baseTextColor == baseTextColor &&
      other.padding == padding &&
      other.placeholder == placeholder &&
      other.baseFontFamily == baseFontFamily &&
      other.barPosition == barPosition &&
      other.enableVideo == enableVideo &&
      listEquals(other.toolbarItems, toolbarItems) &&
      other.toolbarHeight == toolbarHeight &&
      other.labels == labels;

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        baseTextColor,
        padding,
        placeholder,
        baseFontFamily,
        barPosition,
        enableVideo,
        Object.hashAll(toolbarItems),
        toolbarHeight,
        labels,
      );
}
