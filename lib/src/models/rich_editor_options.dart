import 'package:flutter/material.dart';

import 'enum/bar_position.dart';

class RichEditorOptions {
  Color? backgroundColor;
  Color? baseTextColor;
  EdgeInsets? padding;
  String? placeholder;
  String? baseFontFamily;
  BarPosition? barPosition;
  bool? enableVideo;

  RichEditorOptions({
    this.backgroundColor,
    this.baseTextColor,
    this.padding,
    this.placeholder,
    this.baseFontFamily,
    this.barPosition,
    this.enableVideo = true,
  });
}
