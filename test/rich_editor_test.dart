import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_editor/rich_editor.dart';

/// Records the commands sent to the editor instead of running them.
class _RecordingExecutor extends JavascriptExecutorBase {
  final List<String> commands = [];
  Object? result;

  @override
  executeJavascript(String command) async {
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
  return jsonDecode('[${command.substring(name.length + 1, command.length - 2)}]')
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

  test('colors are sent as quoted hex strings', () async {
    await executor.setTextColor(const Color(0xFF112233));
    expect(_args(executor.commands.single, 'setTextColor'), ['#112233']);
  });

  test('insertVideo sends a real boolean for fromDevice', () async {
    await executor.insertVideo('https://example.com/a.mp4', fromDevice: false);
    expect(_args(executor.commands.single, 'insertVideo'),
        ['https://example.com/a.mp4', 300, 220, false]);
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
}
