import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rich_editor/src/extensions/extensions.dart';
import 'package:rich_editor/src/models/callbacks/did_html_change_listener.dart';
import 'package:rich_editor/src/models/callbacks/html_changed_listener.dart';
import 'package:rich_editor/src/models/callbacks/loaded_listener.dart';
import 'package:rich_editor/src/models/enum/command_name.dart';

import '../models/command_state.dart';

/// A class that handles all editor-related javascript functions
class JavascriptExecutorBase {
  InAppWebViewController? _controller;

  String defaultHtml = "<p>\u200B</p>";

  String editorStateChangedCallbackScheme = "editor-state-changed-callback://";

  String defaultEncoding = "UTF-8";

  String? htmlField = "";

  var didHtmlChange = false;

  Map<CommandName, CommandState> commandStates = {};

  List<Map<CommandName, CommandState>> commandStatesChangedListeners =
      <Map<CommandName, CommandState>>[];

  List<DidHtmlChangeListener> didHtmlChangeListeners =
      <DidHtmlChangeListener>[];

  List<HtmlChangedListener> htmlChangedListeners = <HtmlChangedListener>[];

  // protected val fireHtmlChangedListenersQueue = AsyncProducerConsumerQueue<String>(1) { html ->
  // fireHtmlChangedListeners(html)
  // }

  bool isLoaded = false;

  List<LoadedListener> loadedListeners = <LoadedListener>[];

  /// Initialise the controller so we don't have to
  /// pass a controller into every Method
  init(InAppWebViewController? controller) {
    _controller = controller;
  }

  /// Run Javascript commands in the editor using the webview controller
  executeJavascript(String command) async {
    if (_controller == null) {
      return null; // Silently return if controller is not ready
    }
    return await _controller!.evaluateJavascript(source: 'editor.$command');
  }

  String getCachedHtml() {
    return htmlField!;
  }

  /// Display HTML data in editor
  setHtml(String html) async {
    String? baseUrl;
    String encodedHtml = encodeHtml(html);
    await executeJavascript(
        "setHtml('$encodedHtml', ${jsonEncode(baseUrl)});");
    htmlField = html;
  }

  /// Get current HTML data from Editor
  getCurrentHtml() async {
    String? html = await executeJavascript('getEncodedHtml();');
    String? decodedHtml = decodeHtml(html!);
    if (decodedHtml!.startsWith('"') && decodedHtml.endsWith('"')) {
      decodedHtml = decodedHtml.substring(1, decodedHtml.length - 1);
    }
    // Decode HTML entities like &amp; back to &
    decodedHtml = _decodeHtmlEntities(decodedHtml);
    return decodedHtml;
  }

  /// Check if editor's content has been modified
  bool isDefaultRichTextEditorHtml(String html) {
    return defaultHtml == html;
  }

  // Text commands

  /// Undo last editor command/action
  undo() async {
    await executeJavascript("undo();");
  }

  /// Redo last editor command/action
  redo() async {
    await executeJavascript("redo();");
  }

  /// Make selected or subsequent text Bold
  setBold() async {
    await executeJavascript("setBold();");
  }

  /// Make selected or subsequent text Italic
  setItalic() async {
    await executeJavascript("setItalic();");
  }

  /// Make selected or subsequent text Underlined
  setUnderline() async {
    await executeJavascript("setUnderline();");
  }

  /// Make selected or subsequent text Subscript
  setSubscript() async {
    await executeJavascript("setSubscript();");
  }

  /// Make selected or subsequent text Superscript
  setSuperscript() async {
    await executeJavascript("setSuperscript();");
  }

  /// Strike through selected text
  setStrikeThrough() async {
    await executeJavascript("setStrikeThrough();");
  }

  /// Set a [Color] for the selected text
  setTextColor(Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript("setTextColor('$hex');");
  }

  /// Set a [Color] for the selected text's background
  setTextBackgroundColor(Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript("setTextBackgroundColor('$hex');");
  }

  /// Apply a font face to selected text
  setFontName(String fontName) async {
    await executeJavascript("setFontName('$fontName');");
  }

  /// Apply a font size to selected text
  /// (Value can only be between 1 and 7)
  setFontSize(int fontSize) async {
    if (fontSize < 1 || fontSize > 7) {
      throw ("Font size should have a value between 1-7");
    }
    await executeJavascript("setFontSize('$fontSize');");
  }

  /// Apply a Heading style to selected text
  /// (Value can only be between 1 and 6)
  setHeading(int heading) async {
    await executeJavascript("setHeading('$heading');");
  }

  setFormattingToParagraph() async {
    await executeJavascript("setFormattingToParagraph();");
  }

  setPreformat() async {
    await executeJavascript("setPreformat();");
  }

  /// Create BlockQuote / make selected text a BlockQuote
  setBlockQuote() async {
    await executeJavascript("setBlockQuote();");
  }

  /// Remove formatting from selected text
  removeFormat() async {
    await executeJavascript("removeFormat();");
  }

  /// Align content left
  setJustifyLeft() async {
    await executeJavascript("setJustifyLeft();");
  }

  /// Align content center
  setJustifyCenter() async {
    await executeJavascript("setJustifyCenter();");
  }

  /// Align content right
  setJustifyRight() async {
    await executeJavascript("setJustifyRight();");
  }

  /// Justify content
  setJustifyFull() async {
    await executeJavascript("setJustifyFull();");
  }

  /// Add indentation
  setIndent() async {
    await executeJavascript("setIndent();");
  }

  /// Remove indentation
  setOutdent() async {
    await executeJavascript("setOutdent();");
  }

  /// Start an unordered list
  insertBulletList() async {
    await executeJavascript("insertBulletList();");
  }

  /// Start a ordered list
  insertNumberedList() async {
    await executeJavascript("insertNumberedList();");
  }

  // Insert element
  /// Insert hyper link / make selected text an hyperlink
  insertLink(String url, String title) async {
    if (url.isEmpty) return;
    await executeJavascript(
        "insertLink('${_escapeJavaScriptString(url)}', ${jsonEncode(title)});");
  }

  /// The rotation parameter is used to signal that the image is rotated and should be rotated by CSS by given value.
  /// Rotation can be one of the following values: 0, 90, 180, 270.
  insertImage(
    String url, {
    String? alt,
    int? width,
    int? height,
    int? rotation,
  }) async {
    if (url.isEmpty) return;

    rotation ??= 0;
    width ??= 300;
    height ??= 300;
    alt ??= '';
    await executeJavascript(
      "insertImage('${_escapeJavaScriptString(url)}', ${jsonEncode(alt)}, '$width', '$height', $rotation);",
    );
  }

  /// Insert video from Youtube or Device
  /// might work with dailymotion but i've not tested that
  insertVideo(
    String url, {
    int? width,
    int? height,
    bool fromDevice = true,
  }) async {
    if (url.isEmpty) return;

    bool? local;
    local = fromDevice ? true : null;
    width ??= 300;
    height ??= 220;
    // check if link is yt link
    if (url.contains('youtu')) {
      // Get Video id from link.
      String youtubeId = url.split(r'?v=')[1];
      url = 'https://www.youtube.com/embed/$youtubeId';
    }
    await executeJavascript(
      "insertVideo('${_escapeJavaScriptString(url)}', '$width', '$height', $local);",
    );
  }

  /// Add a checkbox to the current editor
  insertCheckbox(String text) async {
    await executeJavascript("insertCheckbox('$text');");
  }

  /// Insert HTML code into the editor
  /// (It wont display the HTML code but it'll render it)
  insertHtml(String html) async {
    String? encodedHtml = encodeHtml(html);
    await executeJavascript("insertHtml('$encodedHtml');");
  }

  /// Enable Images resizing
  makeImagesResizeable() async {
    await executeJavascript("makeImagesResizeable();");
  }

  /// Disable Images resizing
  disableImageResizing() async {
    await executeJavascript("disableImageResizing();");
  }

  // Editor settings commands
  /// Focus on editor and bring up keyboard
  focus() async {
    await executeJavascript("focus();");
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  /// Remove focus from the editor and close the keyboard
  unFocus() async {
    await executeJavascript("blurFocus();");
  }

  /// Set a [Color] for the editor's background
  setBackgroundColor(Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript("setBackgroundColor('$hex');");
  }

  /// Set an image for the editor's background
  setBackgroundImage(String image) async {
    await executeJavascript("setBackgroundImage('$image');");
  }

  /// Set a default editor text color
  setBaseTextColor(Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript("setBaseTextColor('$hex');");
  }

  /// Set a default editor text font family
  setBaseFontFamily(String fontFamily) async {
    await executeJavascript("setBaseFontFamily('$fontFamily');");
  }

  /// Add padding to the editor's content
  setPadding(EdgeInsets? padding) async {
    String left = padding!.left.toString();
    String top = padding.top.toString();
    String right = padding.right.toString();
    String bottom = padding.bottom.toString();
    await executeJavascript(
        "setPadding('${left}px', '${top}px', '${right}px', '${bottom}px');");
  }

  /// Set a hint when the editor is empty
  /// Doesn't actually work for now
  setPlaceholder(String placeholder) async {
    await executeJavascript("setPlaceholder('$placeholder');");
  }

  /// Set editor's width in pixels
  setEditorWidth(int px) async {
    await executeJavascript("setWidth('${px}px');");
  }

  /// Set editor's height in pixels
  setEditorHeight(int px) async {
    await executeJavascript("setHeight('${px}px');");
  }

  /// Enable text input on editor
  setInputEnabled(bool inputEnabled) async {
    await executeJavascript("setInputEnabled($inputEnabled);");
  }

  decodeHtml(String html) {
    return Uri.decodeFull(html);
  }

  encodeHtml(String html) {
    return Uri.encodeFull(html);
  }

  /// Escapes a string for safe use in JavaScript string literals
  String _escapeJavaScriptString(String input) {
    return input
        .replaceAll('\\', '\\\\') // Escape backslashes first
        .replaceAll("'", "\\'")   // Escape single quotes
        .replaceAll('"', '\\"')   // Escape double quotes
        .replaceAll('\n', '\\n')  // Escape newlines
        .replaceAll('\r', '\\r')  // Escape carriage returns
        .replaceAll('\t', '\\t'); // Escape tabs
  }

  /// Decodes common HTML entities back to their original characters
  String _decodeHtmlEntities(String input) {
    return input
        .replaceAll('&amp;', '&')   // Decode ampersands first
        .replaceAll('&lt;', '<')    // Decode less than
        .replaceAll('&gt;', '>')    // Decode greater than
        .replaceAll('&quot;', '"')  // Decode double quotes
        .replaceAll('&#x27;', "'")  // Decode single quotes (hex)
        .replaceAll('&#39;', "'")   // Decode single quotes (decimal)
        .replaceAll('&nbsp;', ' '); // Decode non-breaking spaces
  }

// bool shouldOverrideUrlLoading(String url) {
//   String decodedUrl;
//   try {
//     decodedUrl = decodeHtml(url);
//   } catch (e) {
//     // No handling
//     return false;
//   }
//
//   if (url.indexOf(editorStateChangedCallbackScheme) == 0) {
//     editorStateChanged(
//         decodedUrl.substring(editorStateChangedCallbackScheme.length));
//     return true;
//   }
//
//   return false;
// }
//
// editorStateChanged(String statesString) {
//   try {
//     var editorState = EditorState.fromJson(jsonDecode(statesString));
//
//     bool currentHtmlChanged = this.htmlField != editorState.html;
//     this.htmlField = editorState.html;
//
//     retrievedEditorState(
//         editorState.didHtmlChange!, editorState.commandStates!);
//
//     if (currentHtmlChanged) {
//       // fireHtmlChangedListenersAsync(editorState.html);
//     }
//   } catch (e) {
//     throw ("Could not parse command states: $statesString $e");
//   }
// }
//
// retrievedEditorState(
//     bool didHtmlChange, Map<CommandName, CommandState> commandStates) {
//   if (this.didHtmlChange != didHtmlChange) {
//     this.didHtmlChange = didHtmlChange;
//     didHtmlChangeListeners.forEach((element) {
//       element.didHtmlChange(didHtmlChange);
//     });
//   }
//
//   handleRetrievedCommandStates(commandStates);
// }
//
// handleRetrievedCommandStates(Map<CommandName, CommandState> commandStates) {
//   determineDerivedCommandStates(commandStates);
//
//   this.commandStates = commandStates;
//   commandStatesChangedListeners.forEach((element) {
//     element = this.commandStates;
//   });
// }
//
// determineDerivedCommandStates(Map<CommandName, CommandState> commandStates) {
//   if (commandStates[CommandName.formatBlock] != null) {
//     var formatCommandState = commandStates[CommandName.formatBlock];
//     commandStates.update(
//       CommandName.h1,
//       (val) => CommandState(formatCommandState!.executable,
//           isFormatActivated(formatCommandState, "h1")),
//     );
//     commandStates.update(
//         CommandName.h2,
//         (val) => CommandState(formatCommandState!.executable,
//             isFormatActivated(formatCommandState, "h2")));
//     commandStates.update(
//       CommandName.h3,
//       (val) => CommandState(formatCommandState!.executable,
//           isFormatActivated(formatCommandState, "h3")),
//     );
//     commandStates.update(
//       CommandName.h4,
//       (val) => CommandState(formatCommandState!.executable,
//           isFormatActivated(formatCommandState, "h4")),
//     );
//     commandStates.update(
//       CommandName.h5,
//       (val) => CommandState(formatCommandState!.executable,
//           isFormatActivated(formatCommandState, "h5")),
//     );
//     commandStates.update(
//       CommandName.h6,
//       (val) => CommandState(formatCommandState!.executable,
//           isFormatActivated(formatCommandState, "h6")),
//     );
//     commandStates.update(
//       CommandName.p,
//       (val) => CommandState(formatCommandState!.executable,
//           isFormatActivated(formatCommandState, "p")),
//     );
//     commandStates.update(
//       CommandName.pre,
//       (val) => CommandState(formatCommandState!.executable,
//           isFormatActivated(formatCommandState, "pre")),
//     );
//     commandStates.update(
//       CommandName.br,
//       (val) => CommandState(formatCommandState!.executable,
//           isFormatActivated(formatCommandState, "")),
//     );
//     commandStates.update(
//       CommandName.blockQuote,
//       (val) => CommandState(formatCommandState!.executable,
//           isFormatActivated(formatCommandState, "blockquote")),
//     );
//   }
//
//   if (commandStates[CommandName.insertHtml] != null) {
//     CommandState? insertHtmlState = commandStates[CommandName.insertHtml];
//     commandStates.update(CommandName.insertLink, (val) => insertHtmlState!);
//     commandStates.update(CommandName.insertImage, (val) => insertHtmlState!);
//     commandStates.update(
//         CommandName.insertCheckbox, (val) => insertHtmlState!);
//   }
// }
//
// String isFormatActivated(CommandState formatCommandState, String format) {
//   return (formatCommandState.value == format)
//       .toString(); // rich_text_editor.js reports boolean values as string, so we also have to convert it to string
// }
//
// addCommandStatesChangedListener(
//     Map<CommandName, CommandState> commandStates) {
//   commandStatesChangedListeners.add(commandStates);
//
//   // listener.invoke(commandStates);
// }
//
// addDidHtmlChangeListener(DidHtmlChangeListener listener) {
//   didHtmlChangeListeners.add(listener);
// }
//
// addHtmlChangedListener(HtmlChangedListener listener) {
//   htmlChangedListeners.add(listener);
// }
}
