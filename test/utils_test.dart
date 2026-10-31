import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_editor/src/extensions/extensions.dart';
import 'package:rich_editor/src/models/system_font.dart';
import 'package:rich_editor/src/utils/font_list_parser.dart';
import 'package:rich_editor/src/utils/video_url.dart';

void main() {
  group('youtubeEmbedUrl', () {
    const embed = 'https://www.youtube.com/embed/dQw4w9WgXcQ';

    for (final url in [
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://youtube.com/watch?v=dQw4w9WgXcQ&list=PL123&t=42s',
      'https://m.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://youtu.be/dQw4w9WgXcQ',
      'https://youtu.be/dQw4w9WgXcQ?si=abc',
      'https://www.youtube.com/shorts/dQw4w9WgXcQ',
      'https://www.youtube.com/embed/dQw4w9WgXcQ',
      'https://www.youtube.com/live/dQw4w9WgXcQ?feature=share',
      ' https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ ',
    ]) {
      test(url, () => expect(youtubeEmbedUrl(url), embed));
    }

    for (final url in [
      'https://example.com/watch?v=dQw4w9WgXcQ',
      'https://notyoutube.com/watch?v=dQw4w9WgXcQ',
      'https://www.youtube.com/',
      'https://www.youtube.com/watch',
      'https://www.youtube.com/watch?v=<script>',
      'https://example.com/video.mp4',
      'not a url',
    ]) {
      test('rejects $url', () => expect(youtubeEmbedUrl(url), isNull));
    }
  });

  group('colors', () {
    test('opaque colors become hex', () {
      expect(const Color(0xFF00FF7F).toCssColorString(), '#00ff7f');
    });

    test('translucent colors keep their alpha', () {
      expect(const Color(0x0000FF00).toCssColorString(), 'rgba(0, 255, 0, 0)');
      expect(const Color(0xFF0000FF).withValues(alpha: 0.5).toCssColorString(),
          'rgba(0, 0, 255, 0.502)');
    });

    test('parses the colors the editor reports', () {
      expect(parseCssColor('#ff0000'), const Color(0xFFFF0000));
      expect(parseCssColor('rgb(0, 128, 255)'), const Color(0xFF0080FF));
      expect(parseCssColor('rgba(0, 0, 0, 0)'), const Color(0x00000000));
      expect(parseCssColor('rgba(10, 20, 30, 0.5)')?.toARGB32(), 0x800A141E);
      expect(parseCssColor('false'), isNull);
      expect(parseCssColor(''), isNull);
    });
  });

  group('FontListParser.parseFontsXml', () {
    const xml = '''<?xml version="1.0" encoding="utf-8"?>
<familyset version="23">
    <family name="sans-serif">
        <font weight="100" style="normal">Roboto-Thin.ttf</font>
        <font weight="400" style="italic">Roboto-Italic.ttf</font>
        <font weight="400" style="normal">Roboto-Regular.ttf</font>
        <font weight="700" style="normal">Roboto-Bold.ttf</font>
    </family>
    <family name="serif">
        <font weight="400" style="normal">
            NotoSerif-Regular.ttf
            <axis tag="wght" stylevalue="400" />
        </font>
    </family>
    <family lang="und-Zsye">
        <font weight="400" style="normal">NotoColorEmoji.ttf</font>
    </family>
    <family name="cursive">
        <font weight="700" style="normal">DancingScript-Bold.ttf</font>
    </family>
    <alias name="sans-serif-thin" to="sans-serif" weight="100" />
    <alias name="arial" to="sans-serif" />
    <alias name="serif-bold" to="serif" weight="700" />
    <alias name="broken" to="missing" />
</familyset>''';

    test('picks regular fonts per family and resolves aliases', () {
      expect(FontListParser.parseFontsXml(xml), const [
        SystemFont('sans-serif', '/system/fonts/Roboto-Regular.ttf'),
        SystemFont('serif', '/system/fonts/NotoSerif-Regular.ttf'),
        SystemFont('cursive', '/system/fonts/DancingScript-Bold.ttf'),
        SystemFont('sans-serif-thin', '/system/fonts/Roboto-Thin.ttf'),
        SystemFont('arial', '/system/fonts/Roboto-Regular.ttf'),
      ]);
    });
  });
}
