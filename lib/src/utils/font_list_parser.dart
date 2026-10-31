import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:rich_editor/src/models/system_font.dart';
import 'package:xml/xml.dart';

/// A simple port of FontListParser from Java to Dart
/// See https://stackoverflow.com/a/29533686/10835183
class FontListParser {
  File androidFontsFile = File("/system/etc/fonts.xml");
  File androidSystemFontsFile = File("/system/etc/system_fonts.xml");

  static const _systemFontsDir = '/system/fonts/';

  /// Gets fonts from the fonts xml files in the android system
  List<SystemFont> getSystemFonts() {
    File fontsXml;
    if (androidFontsFile.existsSync()) {
      fontsXml = androidFontsFile;
    } else if (androidSystemFontsFile.existsSync()) {
      fontsXml = androidSystemFontsFile;
    } else {
      throw const FileSystemException(
          'fonts.xml does not exist on this system');
    }

    final fonts = parseFontsXml(fontsXml.readAsStringSync());
    if (fonts.isEmpty) {
      throw Exception("No system fonts found.");
    }
    return fonts;
  }

  /// Parses an Android fonts.xml into one font per family and alias,
  /// preferring the regular (400) weight.
  @visibleForTesting
  static List<SystemFont> parseFontsXml(String xml) {
    final familySet = XmlDocument.parse(xml).rootElement;
    final families = familySet.findElements('family').toList();
    final fonts = <SystemFont>[];

    void add(String name, XmlElement font) {
      final file = font.innerText.trim();
      if (file.isEmpty) return;
      final systemFont = SystemFont(name, '$_systemFontsDir$file');
      if (!fonts.any((f) => f.name == name)) fonts.add(systemFont);
    }

    for (final family in families) {
      final name = family.getAttribute('name');
      final familyFonts = family.findElements('font').toList();
      if (name == null || familyFonts.isEmpty) continue;
      add(name, _fontWithWeight(familyFonts, '400') ?? familyFonts.first);
    }

    for (final alias in familySet.findElements('alias')) {
      final name = alias.getAttribute('name');
      final to = alias.getAttribute('to');
      if (name == null || to == null) continue;

      for (final family in families) {
        if (family.getAttribute('name') != to) continue;
        final familyFonts = family.findElements('font').toList();
        final weight = alias.getAttribute('weight');
        final font = weight != null
            ? _fontWithWeight(familyFonts, weight)
            : _fontWithWeight(familyFonts, '400') ??
                (familyFonts.isEmpty ? null : familyFonts.first);
        if (font != null) add(name, font);
        break;
      }
    }

    return fonts;
  }

  static XmlElement? _fontWithWeight(List<XmlElement> fonts, String weight) {
    for (final font in fonts) {
      if (font.getAttribute('weight') == weight &&
          (font.getAttribute('style') ?? 'normal') == 'normal') {
        return font;
      }
    }
    return null;
  }

  /// Gets font from the list defined in case the above function doesn't work
  List<SystemFont> safelyGetSystemFonts() {
    try {
      return getSystemFonts();
    } catch (e) {
      const defaultSystemFonts = [
        ["cursive", "DancingScript-Regular.ttf"],
        ["monospace", "DroidSansMono.ttf"],
        ["sans-serif", "Roboto-Regular.ttf"],
        ["sans-serif-light", "Roboto-Light.ttf"],
        ["sans-serif-medium", "Roboto-Medium.ttf"],
        ["sans-serif-black", "Roboto-Black.ttf"],
        ["sans-serif-condensed", "RobotoCondensed-Regular.ttf"],
        ["sans-serif-thin", "Roboto-Thin.ttf"],
        ["serif", "NotoSerif-Regular.ttf"]
      ];
      List<SystemFont> fonts = <SystemFont>[];
      for (final names in defaultSystemFonts) {
        File file = File('$_systemFontsDir${names[1]}');
        if (file.existsSync()) {
          fonts.add(SystemFont(names[0], file.path));
        }
      }
      return fonts;
    }
  }
}
