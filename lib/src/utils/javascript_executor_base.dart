import 'package:flutter/material.dart';
import 'package:rich_editor/src/extensions/extensions.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JavascriptExecutorBase {
  WebViewController? _controller;

  init(WebViewController controller) {
    _controller = controller;
  }

  executeJavascript(String command) async {
    return await _controller!.evaluateJavascript('editor.$command');
  }

  setHtml(String html) async {
    String? baseUrl;
    await executeJavascript(
        "setHtml('" + encodeHtml(html) + "', '$baseUrl');");
  }

  getHtml() async {
    String? html = await executeJavascript('getEncodedHtml()');
    String? decodedHtml = Uri.decodeFull(html!);
    if (decodedHtml.startsWith('"') && decodedHtml.endsWith('"')) {
      decodedHtml = decodedHtml.substring(1, decodedHtml.length - 1);
    }
    return decodedHtml;
  }

  // Text commands
  undo() async {
    await executeJavascript("undo()");
  }

  redo() async {
    await executeJavascript("redo()");
  }

  setBold() async {
    await executeJavascript("setBold()");
  }

  setItalic() async {
    await executeJavascript("setItalic()");
  }

  setUnderline() async {
    await executeJavascript("setUnderline()");
  }

  setSubscript() async {
    await executeJavascript("setSubscript()");
  }

  setSuperscript() async {
    await executeJavascript("setSuperscript()");
  }

  setStrikeThrough() async {
    await executeJavascript("setStrikeThrough()");
  }

  setTextColor(Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript("setTextColor('$hex')");
  }

  setFontName(String fontName) async {
    await executeJavascript("setFontName('$fontName')");
  }

  setFontSize(int fontSize) async {
    if (fontSize < 1 || fontSize > 7) {
      throw ("Font size should have a value between 1-7");
    }
    await executeJavascript("setFontSize('$fontSize')");
  }

  setHeading(int heading) async {
    await executeJavascript("setHeading('$heading')");
  }

  setFormattingToParagraph() async {
    await executeJavascript("setFormattingToParagraph()");
  }

  setPreformat() async {
    await executeJavascript("setPreformat()");
  }

  setBlockQuote() async {
    await executeJavascript("setBlockQuote()");
  }

  removeFormat() async {
    await executeJavascript("removeFormat()");
  }

  setJustifyLeft() async {
    await executeJavascript("setJustifyLeft()");
  }

  setJustifyCenter() async {
    await executeJavascript("setJustifyCenter()");
  }

  setJustifyRight() async {
    await executeJavascript("setJustifyRight()");
  }

  setJustifyFull() async {
    await executeJavascript("setJustifyFull()");
  }

  setIndent() async {
    await executeJavascript("setIndent()");
  }

  setOutdent() async {
    await executeJavascript("setOutdent()");
  }

  insertBulletList() async {
    await executeJavascript("insertBulletList()");
  }

  insertNumberedList() async {
    await executeJavascript("insertNumberedList()");
  }

  // Insert element
  insertLink(String url, String title) async {
    await executeJavascript("insertLink('$url', '$title')");
  }

  /// The rotation parameter is used to signal that the image is rotated and should be rotated by CSS by given value.
  /// Rotation can be one of the following values: 0, 90, 180, 270.
  insertImage(String url, String alt,
      String? width, String? height, int? rotation) async {
    if (rotation == null) rotation = 0;
    await executeJavascript(
      "insertImage('$url', '$alt', '$width', '$height', $rotation)",
    );
  }

  insertCheckbox(String text) async {
    await executeJavascript("insertCheckbox('$text')");
  }

  insertHtml(String html) async {
    String? encodedHtml = encodeHtml(html);
    await executeJavascript("insertHtml('$encodedHtml')");
  }

  makeImagesResizeable() async {
    await executeJavascript("makeImagesResizeable()");
  }

  disableImageResizing() async {
    await executeJavascript("disableImageResizing()");
  }

  static decodeHtml(String html) {
    return Uri.decodeFull(html);
  }

  static encodeHtml(String html) {
    return Uri.encodeFull(html);
  }
}
