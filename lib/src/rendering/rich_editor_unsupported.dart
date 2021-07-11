import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rich_editor/src/models/rich_editor_options.dart';
import 'package:rich_editor/src/utils/javascript_executor_base.dart';

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
  // final Key _mapKey = UniqueKey();
  //
  // int port = 5321;
  // String html = '';
  // LocalServer? localServer;
  JavascriptExecutorBase javascriptExecutor = JavascriptExecutorBase();

  @override
  Widget build(BuildContext context) {
    return Text(
        'Rich Editor is does not support thisplatform');
  }

  /// Get current HTML from editor
  Future<String?> getHtml() async {
    throw ('Platform not supported');
  }

  /// Set your HTML to the editor
  setHtml(String html) async {
    throw ('Platform not supported');
  }

  /// Hide the keyboard using JavaScript since it's being opened in a WebView
  /// https://stackoverflow.com/a/8263376/10835183
  unFocus() {
    throw ('Platform not supported');
  }

  /// Clear editor content using Javascript
  clear() {
    throw ('Platform not supported');
  }

  /// Focus and Show the keyboard using JavaScript
  /// https://stackoverflow.com/a/6809236/10835183
  focus() {
    throw ('Platform not supported');
  }

  /// Add custom CSS code to Editor
  loadCSS(String cssFile) {
    throw ('Platform not supported');
  }

  /// if html is equal to html RichTextEditor sets by default at start
  /// (<p>​</p>) so that RichTextEditor can be considered as 'empty'.
  Future<bool> isEmpty() async {
    throw ('Platform not supported');
  }

  /// Enable Editing (If editing is disabled)
  enableEditing() async {
    throw ('Platform not supported');
  }

  /// Disable Editing (Could be used for a 'view mode')
  disableEditing() async {
    throw ('Platform not supported');
  }
}
