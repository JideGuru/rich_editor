import 'package:flutter/material.dart';
import 'package:rich_editor/src/extensions/extensions.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JavaScriptExecutorBase {
  static executeJavascript(WebViewController controller, String command) async {
    return await controller.evaluateJavascript('editor.$command');
  }

  static setHtml(WebViewController controller, String html) async {
    String? baseUrl;
    await executeJavascript(
        controller, "setHtml('" + encodeHtml(html) + "', '$baseUrl');");
  }

  static getHtml(WebViewController controller) async {
    String? html = await executeJavascript(controller, 'getEncodedHtml()');
    String? decodedHtml = Uri.decodeFull(html!);
    if (decodedHtml.startsWith('"') && decodedHtml.endsWith('"')) {
      decodedHtml = decodedHtml.substring(1, decodedHtml.length - 1);
    }
    return decodedHtml;
  }

  // Text commands
  static undo(WebViewController controller) async {
    await executeJavascript(controller, "undo()");
  }

  static redo(WebViewController controller) async {
    await executeJavascript(controller, "redo()");
  }

  static setBold(WebViewController controller) async {
    await executeJavascript(controller, "setBold()");
  }

  static setItalic(WebViewController controller) async {
    await executeJavascript(controller, "setItalic()");
  }

  static setUnderline(WebViewController controller) async {
    await executeJavascript(controller, "setUnderline()");
  }

  static setSubscript(WebViewController controller) async {
    await executeJavascript(controller, "setSubscript()");
  }

  static setSuperscript(WebViewController controller) async {
    await executeJavascript(controller, "setSuperscript()");
  }

  static setStrikeThrough(WebViewController controller) async {
    await executeJavascript(controller, "setStrikeThrough()");
  }

  static setTextColor(WebViewController controller, Color? color) async {
    String? hex = color!.toHexColorString();
    await executeJavascript(controller, "setTextColor('$hex')");
  }

  static setFontName(WebViewController controller, String fontName) async {
    await executeJavascript(controller, "setFontName('$fontName')");
  }

  static setFontSize(WebViewController controller, int fontSize) async {
    if (fontSize < 1 || fontSize > 7) {
      throw ("Font size should have a value between 1-7");
    }
    await executeJavascript(controller, "setFontSize('$fontSize')");
  }

  static setHeading(WebViewController controller, int heading) async {
    await executeJavascript(controller, "setHeading('$heading')");
  }

  static setFormattingToParagraph(WebViewController controller) async {
    await executeJavascript(controller, "setFormattingToParagraph()");
  }

  static setPreformat(WebViewController controller) async {
    await executeJavascript(controller, "setPreformat()");
  }

  static setBlockQuote(WebViewController controller) async {
    await executeJavascript(controller, "setBlockQuote()");
  }

  static removeFormat(WebViewController controller) async {
    await executeJavascript(controller, "removeFormat()");
  }

  static setJustifyLeft(WebViewController controller) async {
    await executeJavascript(controller, "setJustifyLeft()");
  }

  static setJustifyCenter(WebViewController controller) async {
    await executeJavascript(controller, "setJustifyCenter()");
  }

  static setJustifyRight(WebViewController controller) async {
    await executeJavascript(controller, "setJustifyRight()");
  }

  static setJustifyFull(WebViewController controller) async {
    await executeJavascript(controller, "setJustifyFull()");
  }

  static setIndent(WebViewController controller) async {
    await executeJavascript(controller, "setIndent()");
  }

  static setOutdent(WebViewController controller) async {
    await executeJavascript(controller, "setOutdent()");
  }

  static insertBulletList(WebViewController controller) async {
    await executeJavascript(controller, "insertBulletList()");
  }

  static insertNumberedList(WebViewController controller) async {
    await executeJavascript(controller, "insertNumberedList()");
  }

  static decodeHtml(String html) {
    return Uri.decodeFull(html);
  }

  static encodeHtml(String html) {
    return Uri.encodeFull(html);
  }
}
