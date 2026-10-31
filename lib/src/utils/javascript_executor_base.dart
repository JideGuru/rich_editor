import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:rich_editor/src/extensions/extensions.dart';
import 'package:rich_editor/src/utils/video_url.dart';

/// A class that handles all editor-related javascript functions
///
/// Every argument is passed through [jsonEncode], so any string reaches the
/// editor unchanged.
class JavascriptExecutorBase {
  InAppWebViewController? _controller;

  /// Whether the editor page is loaded and accepting commands.
  bool get isReady => _controller != null;

  /// Initialise the controller so we don't have to
  /// pass a controller into every Method
  void init(InAppWebViewController? controller) {
    _controller = controller;
  }

  /// Run Javascript commands in the editor using the webview controller
  ///
  /// Does nothing and returns null until the editor is loaded.
  Future<Object?> executeJavascript(String command) async {
    final controller = _controller;
    if (controller == null) return null;
    return await controller.evaluateJavascript(source: 'editor.$command')
        as Object?;
  }

  /// Display HTML data in editor
  Future<void> setHtml(String html) async {
    await executeJavascript("setHtml(${jsonEncode(html)});");
  }

  /// Get current HTML data from Editor
  ///
  /// The editor percent-encodes its HTML so it crosses the WebView bridge as
  /// plain ASCII; it is returned exactly as the editor holds it, entities
  /// included. Returns an empty string while the editor is empty or not
  /// loaded yet.
  Future<String> getCurrentHtml() => _getEncoded('getEncodedHtml();');

  /// The editor content as plain text, paragraphs and line breaks as new
  /// lines.
  Future<String> getText() => _getEncoded('getEncodedText();');

  /// The content as a [Tiptap](https://tiptap.dev/docs/editor/core-concepts/schema)
  /// (ProseMirror) JSON document: `{"type": "doc", "content": [...]}`.
  ///
  /// Returns a document with one empty paragraph while the editor is not
  /// loaded yet.
  Future<Map<String, dynamic>> getJson() async {
    final json = await _getEncoded('getEncodedJson();');
    if (json.isEmpty) return emptyJsonDocument;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Replaces the content with a JSON document, as [getJson] returns it.
  ///
  /// Returns false, leaving the content as it was, when [json] has nodes,
  /// marks or attributes the editor doesn't know, or nodes where they can't
  /// go (e.g. text directly in the document).
  Future<bool> setJson(Map<String, dynamic> json) async {
    final result = await executeJavascript('setJson(${jsonEncode(json)});');
    return result == true || result.toString() == 'true';
  }

  /// What [getJson] returns for an empty editor.
  static const emptyJsonDocument = <String, dynamic>{
    'type': 'doc',
    'content': [
      {'type': 'paragraph'}
    ],
  };

  /// Runs [command], which returns a string encoded with
  /// `encodeURIComponent`, so it survives every platform's bridge.
  Future<String> _getEncoded(String command) async {
    String? encoded = (await executeJavascript(command))?.toString();
    if (encoded == null) return '';
    // Some platforms hand back the JS string still wrapped in quotes.
    // encodeURIComponent never emits a quote, so stripping them is safe.
    if (encoded.length >= 2 &&
        encoded.startsWith('"') &&
        encoded.endsWith('"')) {
      encoded = encoded.substring(1, encoded.length - 1);
    }
    return Uri.decodeComponent(encoded);
  }

  /// Whether the editor holds no text and no media.
  Future<bool> isEmpty() async {
    final result = await executeJavascript('isEmpty();');
    return result == null || result == true || result.toString() == 'true';
  }

  /// Remove all content from the editor
  Future<void> clear() => setHtml('');

  // Text commands

  /// Undo last editor command/action
  Future<void> undo() async {
    await executeJavascript("undo();");
  }

  /// Redo last editor command/action
  Future<void> redo() async {
    await executeJavascript("redo();");
  }

  /// Make selected or subsequent text Bold
  Future<void> setBold() async {
    await executeJavascript("setBold();");
  }

  /// Make selected or subsequent text Italic
  Future<void> setItalic() async {
    await executeJavascript("setItalic();");
  }

  /// Make selected or subsequent text Underlined
  Future<void> setUnderline() async {
    await executeJavascript("setUnderline();");
  }

  /// Make selected or subsequent text Subscript
  Future<void> setSubscript() async {
    await executeJavascript("setSubscript();");
  }

  /// Make selected or subsequent text Superscript
  Future<void> setSuperscript() async {
    await executeJavascript("setSuperscript();");
  }

  /// Strike through selected text
  Future<void> setStrikeThrough() async {
    await executeJavascript("setStrikeThrough();");
  }

  /// Set a [Color] for the selected text
  Future<void> setTextColor(Color color) async {
    await executeJavascript(
        "setTextColor(${jsonEncode(color.toCssColorString())});");
  }

  /// Set a [Color] for the selected text's background
  ///
  /// A fully transparent color removes the background.
  Future<void> setTextBackgroundColor(Color color) async {
    await executeJavascript(
        "setTextBackgroundColor(${jsonEncode(color.toCssColorString())});");
  }

  /// Apply a font face to selected text
  Future<void> setFontName(String fontName) async {
    await executeJavascript("setFontName(${jsonEncode(fontName)});");
  }

  /// Apply a font size to selected text
  /// (Value can only be between 1 and 7)
  Future<void> setFontSize(int fontSize) async {
    if (fontSize < 1 || fontSize > 7) {
      throw ArgumentError.value(
          fontSize, 'fontSize', 'must be between 1 and 7');
    }
    await executeJavascript("setFontSize($fontSize);");
  }

  /// Apply a Heading style to selected text
  /// (Value can only be between 1 and 6)
  Future<void> setHeading(int heading) async {
    if (heading < 1 || heading > 6) {
      throw ArgumentError.value(heading, 'heading', 'must be between 1 and 6');
    }
    await executeJavascript("setHeading($heading);");
  }

  Future<void> setFormattingToParagraph() async {
    await executeJavascript("setFormattingToParagraph();");
  }

  Future<void> setPreformat() async {
    await executeJavascript("setPreformat();");
  }

  /// Create BlockQuote / make selected text a BlockQuote
  Future<void> setBlockQuote() async {
    await executeJavascript("setBlockQuote();");
  }

  /// Remove formatting from selected text
  Future<void> removeFormat() async {
    await executeJavascript("removeFormat();");
  }

  /// Align content left
  Future<void> setJustifyLeft() async {
    await executeJavascript("setJustifyLeft();");
  }

  /// Align content center
  Future<void> setJustifyCenter() async {
    await executeJavascript("setJustifyCenter();");
  }

  /// Align content right
  Future<void> setJustifyRight() async {
    await executeJavascript("setJustifyRight();");
  }

  /// Justify content
  Future<void> setJustifyFull() async {
    await executeJavascript("setJustifyFull();");
  }

  /// Add indentation
  Future<void> setIndent() async {
    await executeJavascript("setIndent();");
  }

  /// Remove indentation
  Future<void> setOutdent() async {
    await executeJavascript("setOutdent();");
  }

  /// Start an unordered list
  Future<void> insertBulletList() async {
    await executeJavascript("insertBulletList();");
  }

  /// Start a ordered list
  Future<void> insertNumberedList() async {
    await executeJavascript("insertNumberedList();");
  }

  // Insert element
  /// Insert hyper link / make selected text an hyperlink
  ///
  /// Unsafe URLs such as `javascript:` are ignored by the editor.
  Future<void> insertLink(String url, String title) async {
    if (url.isEmpty) return;
    await executeJavascript(
        "insertLink(${jsonEncode(url)}, ${jsonEncode(title)});");
  }

  /// Changes the URL of the link the caret is in.
  ///
  /// Unsafe URLs such as `javascript:` are ignored by the editor.
  Future<void> editLink(String url) async {
    if (url.isEmpty) return;
    await executeJavascript("editLink(${jsonEncode(url)});");
  }

  /// Removes the link the caret is in, keeping its text.
  Future<void> removeLink() async {
    await executeJavascript("removeLink();");
  }

  /// The rotation parameter is used to signal that the image is rotated and should be rotated by CSS by given value.
  /// Rotation can be one of the following values: 0, 90, 180, 270.
  Future<void> insertImage(
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
      "insertImage(${jsonEncode(url)}, ${jsonEncode(alt)}, $width, $height, $rotation);",
    );
  }

  /// Insert video from Youtube or Device
  ///
  /// YouTube links (watch, youtu.be, shorts, ...) are always embedded with
  /// the YouTube player. Other links are played in a `<video>` element when
  /// [fromDevice] is true and embedded in an iframe otherwise.
  Future<void> insertVideo(
    String url, {
    int? width,
    int? height,
    bool fromDevice = true,
  }) async {
    if (url.isEmpty) return;

    width ??= 300;
    height ??= 220;
    final youtubeUrl = youtubeEmbedUrl(url);
    if (youtubeUrl != null) {
      url = youtubeUrl;
      fromDevice = false;
    }
    await executeJavascript(
      "insertVideo(${jsonEncode(url)}, $width, $height, $fromDevice);",
    );
  }

  /// Add a checkbox to the current editor
  Future<void> insertCheckbox(String text) async {
    await executeJavascript("insertCheckbox(${jsonEncode(text)});");
  }

  /// Insert HTML code into the editor
  /// (It wont display the HTML code but it'll render it)
  ///
  /// Scripts and event handler attributes are removed.
  Future<void> insertHtml(String html) async {
    await executeJavascript("insertHtml(${jsonEncode(html)});");
  }

  /// Enable Images resizing
  Future<void> makeImagesResizeable() async {
    await executeJavascript("makeImagesResizeable();");
  }

  /// Disable Images resizing
  Future<void> disableImageResizing() async {
    await executeJavascript("disableImageResizing();");
  }

  // Editor settings commands
  /// Focuses the editor, with the caret at the end, and opens the keyboard.
  ///
  /// Android only opens the keyboard once the user has interacted with the
  /// editor page, e.g. tapped it; until then only the caret is placed.
  Future<void> focus() async {
    await executeJavascript("focus();");
  }

  /// Remove focus from the editor and close the keyboard
  Future<void> unFocus() async {
    await executeJavascript("blurFocus();");
  }

  /// Set a [Color] for the editor's background
  Future<void> setBackgroundColor(Color color) async {
    await executeJavascript(
        "setBackgroundColor(${jsonEncode(color.toCssColorString())});");
  }

  /// Colors links, checkboxes, the caret and selections for a light or dark
  /// background.
  Future<void> setColorScheme(Brightness brightness) async {
    await executeJavascript("setColorScheme(${jsonEncode(brightness.name)});");
  }

  /// Lays the content out left to right or right to left (e.g. Arabic,
  /// Hebrew).
  Future<void> setTextDirection(TextDirection direction) async {
    await executeJavascript("setTextDirection(${jsonEncode(direction.name)});");
  }

  /// Set an image for the editor's background
  ///
  /// [image] is the image URL.
  Future<void> setBackgroundImage(String image) async {
    await executeJavascript("setBackgroundImage(${jsonEncode(image)});");
  }

  /// Set a default editor text color
  Future<void> setBaseTextColor(Color color) async {
    await executeJavascript(
        "setBaseTextColor(${jsonEncode(color.toCssColorString())});");
  }

  /// Set a default editor text font family
  Future<void> setBaseFontFamily(String fontFamily) async {
    await executeJavascript("setBaseFontFamily(${jsonEncode(fontFamily)});");
  }

  /// Add padding to the editor's content
  Future<void> setPadding(EdgeInsets padding) async {
    await executeJavascript(
        "setPadding('${padding.left}px', '${padding.top}px', '${padding.right}px', '${padding.bottom}px');");
  }

  /// Set a hint shown while the editor is empty
  Future<void> setPlaceholder(String placeholder) async {
    await executeJavascript("setPlaceholder(${jsonEncode(placeholder)});");
  }

  /// Set editor's width in pixels
  Future<void> setEditorWidth(int px) async {
    await executeJavascript("setWidth('${px}px');");
  }

  /// Set editor's height in pixels
  Future<void> setEditorHeight(int px) async {
    await executeJavascript("setHeight('${px}px');");
  }

  /// Enable text input on editor
  Future<void> setInputEnabled(bool inputEnabled) async {
    await executeJavascript("setInputEnabled($inputEnabled);");
  }

  /// Add a stylesheet to the editor page
  Future<void> loadCSS(String cssUrl) async {
    await executeJavascript("loadCSS(${jsonEncode(cssUrl)});");
  }
}
