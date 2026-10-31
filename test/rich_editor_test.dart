import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_editor/rich_editor.dart';

// Covers JavascriptExecutorBase, the bridge between Dart and the editor page.

/// Records the commands sent to the editor instead of running them.
class _RecordingExecutor extends JavascriptExecutorBase {
  final List<String> commands = [];
  Object? result;

  @override
  Future<Object?> executeJavascript(String command) async {
    commands.add(command);
    return result;
  }
}

/// Strings that broke the old encode/escape layer.
const _trickyStrings = [
  "C++ rocks",
  "100% sure",
  "it's",
  'say "hi"',
  r'back\slash',
  'line\nbreak',
  '</script><script>alert(1)</script>',
  "'); alert(1); ('",
  '&lt;b&gt; &amp; &nbsp;',
  'emoji 🎉 and ünïcödé',
];

/// Pulls the argument list out of a recorded `name(...);` command and
/// parses it as JSON, the way the JS engine would parse the literals.
List<dynamic> _args(String command, String name) {
  expect(command, startsWith('$name('));
  expect(command, endsWith(');'));
  return jsonDecode(
          '[${command.substring(name.length + 1, command.length - 2)}]')
      as List<dynamic>;
}

void main() {
  late _RecordingExecutor executor;

  setUp(() => executor = _RecordingExecutor());

  group('arguments reach JavaScript unchanged', () {
    for (final s in _trickyStrings) {
      test('setHtml ${jsonEncode(s)}', () async {
        await executor.setHtml(s);
        expect(_args(executor.commands.single, 'setHtml'), [s]);
      });

      test('insertHtml ${jsonEncode(s)}', () async {
        await executor.insertHtml(s);
        expect(_args(executor.commands.single, 'insertHtml'), [s]);
      });

      test('insertLink ${jsonEncode(s)}', () async {
        await executor.insertLink('https://example.com/?q=$s', s);
        expect(_args(executor.commands.single, 'insertLink'),
            ['https://example.com/?q=$s', s]);
      });

      test('insertCheckbox ${jsonEncode(s)}', () async {
        await executor.insertCheckbox(s);
        expect(_args(executor.commands.single, 'insertCheckbox'), [s]);
      });

      test('insertImage ${jsonEncode(s)}', () async {
        await executor.insertImage('https://example.com/$s.png', alt: s);
        expect(_args(executor.commands.single, 'insertImage'),
            ['https://example.com/$s.png', s, 300, 300, 0]);
      });

      test('text settings ${jsonEncode(s)}', () async {
        await executor.setFontName(s);
        await executor.setBaseFontFamily(s);
        await executor.setPlaceholder(s);
        await executor.setBackgroundImage(s);
        expect(_args(executor.commands[0], 'setFontName'), [s]);
        expect(_args(executor.commands[1], 'setBaseFontFamily'), [s]);
        expect(_args(executor.commands[2], 'setPlaceholder'), [s]);
        expect(_args(executor.commands[3], 'setBackgroundImage'), [s]);
      });
    }
  });

  test('colors are sent as CSS strings, keeping transparency', () async {
    await executor.setTextColor(const Color(0xFF112233));
    await executor.setTextBackgroundColor(const Color(0x80FF0000));
    await executor.setTextBackgroundColor(const Color(0x00000000));
    expect(_args(executor.commands[0], 'setTextColor'), ['#112233']);
    expect(_args(executor.commands[1], 'setTextBackgroundColor'),
        ['rgba(255, 0, 0, 0.502)']);
    expect(_args(executor.commands[2], 'setTextBackgroundColor'),
        ['rgba(0, 0, 0, 0)']);
  });

  test('insertVideo sends a real boolean for fromDevice', () async {
    await executor.insertVideo('https://example.com/a.mp4', fromDevice: false);
    expect(_args(executor.commands.single, 'insertVideo'),
        ['https://example.com/a.mp4', 300, 220, false]);
  });

  test('insertVideo embeds YouTube links of any shape', () async {
    await executor.insertVideo('https://youtu.be/dQw4w9WgXcQ?t=42');
    expect(_args(executor.commands.single, 'insertVideo'),
        ['https://www.youtube.com/embed/dQw4w9WgXcQ', 300, 220, false]);
  });

  test('setFontSize rejects values outside 1-7', () async {
    expect(() => executor.setFontSize(0), throwsArgumentError);
    expect(() => executor.setFontSize(8), throwsArgumentError);
    await executor.setFontSize(7);
    expect(executor.commands.single, 'setFontSize(7);');
  });

  test('isEmpty reads the editor result', () async {
    executor.result = false;
    expect(await executor.isEmpty(), isFalse);
    executor.result = true;
    expect(await executor.isEmpty(), isTrue);
  });

  test('setHeading rejects values outside 1-6', () async {
    expect(() => executor.setHeading(0), throwsArgumentError);
    expect(() => executor.setHeading(7), throwsArgumentError);
    await executor.setHeading(2);
    expect(executor.commands.single, 'setHeading(2);');
  });

  group('getCurrentHtml', () {
    // What the editor's getEncodedHtml() hands back: encodeURIComponent(html).
    String encodeLikeJs(String s) => Uri.encodeComponent(s);

    for (final s in _trickyStrings) {
      test('round-trips ${jsonEncode(s)}', () async {
        executor.result = encodeLikeJs(s);
        expect(await executor.getCurrentHtml(), s);
      });
    }

    test('keeps HTML entities as the editor holds them', () async {
      const html = '<p>&lt;script&gt;alert(1)&lt;/script&gt; a&nbsp;b</p>';
      executor.result = encodeLikeJs(html);
      expect(await executor.getCurrentHtml(), html);
    });

    test('strips quotes some platforms wrap the result in', () async {
      executor.result = '"${encodeLikeJs('<p>x</p>')}"';
      expect(await executor.getCurrentHtml(), '<p>x</p>');
    });

    test('returns an empty string before the WebView is ready', () async {
      executor.result = null;
      expect(await executor.getCurrentHtml(), '');
    });
  });

  test('getText reads the encoded text', () async {
    executor.result = Uri.encodeComponent("C++ it's\nline 2");
    expect(await executor.getText(), "C++ it's\nline 2");
    expect(executor.commands.single, 'getEncodedText();');
  });

  test('editLink and removeLink', () async {
    await executor.editLink('');
    await executor.editLink("https://e.com/?q='x'");
    await executor.removeLink();
    expect(_args(executor.commands[0], 'editLink'), ["https://e.com/?q='x'"]);
    expect(executor.commands[1], 'removeLink();');
  });

  group('JSON', () {
    test('getJson decodes the encoded document', () async {
      const json = {
        'type': 'doc',
        'content': [
          {
            'type': 'paragraph',
            'content': [
              {'type': 'text', 'text': "C++ it's \"100%\""}
            ]
          }
        ]
      };
      executor.result = Uri.encodeComponent(jsonEncode(json));
      expect(await executor.getJson(), json);
      expect(executor.commands.single, 'getEncodedJson();');
    });

    test('getJson is an empty document before the WebView is ready', () async {
      executor.result = null;
      expect(
          await executor.getJson(), JavascriptExecutorBase.emptyJsonDocument);
    });

    test('setJson passes the document as a literal and reads the result',
        () async {
      const json = {
        'type': 'doc',
        'content': [
          {
            'type': 'paragraph',
            'content': [
              {'type': 'text', 'text': '</script>\'); alert(1); (\''}
            ]
          }
        ]
      };
      executor.result = true;
      expect(await executor.setJson(json), isTrue);
      expect(_args(executor.commands.single, 'setJson'), [json]);
      executor.result = false;
      expect(await executor.setJson(json), isFalse);
    });
  });

  test('setTextDirection', () async {
    await executor.setTextDirection(TextDirection.rtl);
    expect(_args(executor.commands.single, 'setTextDirection'), ['rtl']);
  });
}
