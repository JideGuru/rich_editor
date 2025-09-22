import 'dart:convert';
import 'dart:io';

import 'package:rich_editor/src/models/alias.dart';
import 'package:rich_editor/src/models/config.dart';
import 'package:rich_editor/src/models/family.dart';
import 'package:rich_editor/src/models/font.dart';
import 'package:rich_editor/src/models/system_font.dart';
import 'package:xml2json/xml2json.dart';

/// A simple port of FontListParser from Java to Dart
/// See https://stackoverflow.com/a/29533686/10835183
class FontListParser {
  File androidFontsFile = File("/system/etc/fonts.xml");
  File androidSystemFontsFile = File("/system/etc/system_fonts.xml");

  /// Gets fonts from the fonts xml files in the android system
  List<SystemFont> getSystemFonts() {
    String fontsXml;
    if (androidFontsFile.existsSync()) {
      fontsXml = androidFontsFile.path;
    } else if (androidSystemFontsFile.existsSync()) {
      fontsXml = androidSystemFontsFile.path;
    } else {
      throw ("fonts.xml does not exist on this system");
    }
    Xml2Json xml2json = Xml2Json();
    xml2json.parse(File(fontsXml).readAsStringSync());
    Map json = jsonDecode(xml2json.toGData());
    Config parser = Config.fromJson(json['familyset']);
    List<SystemFont> fonts = <SystemFont>[];

    for (Family family in parser.families!) {
      if (family.name != null) {
        Font font = Font();
        for (Font f in family.fonts!) {
          font = f;
          if (int.tryParse(f.weight!) == 400) {
            break;
          }
        }
        if (font.t != null) {
          SystemFont systemFont = SystemFont(family.name!, font.t!);
          if (fonts.contains(systemFont)) {
            continue;
          }
          fonts.add(SystemFont(family.name!, font.t!));
        }
      }
    }

    for (Alias alias in parser.aliases!) {
      if (alias.name == null ||
          alias.to == null ||
          int.tryParse(alias.weight ?? '') == 0) {
        continue;
      }
      for (Family family in parser.families!) {
        if (family.name == null || family.name! == alias.to) {
          continue;
        }
        for (Font font in family.fonts!) {
          if (font.weight == alias.weight) {
            fonts.add(SystemFont(alias.name!, font.t ?? ''));
            break;
          }
        }
      }
    }

    if (fonts.isEmpty) {
      throw Exception("No system fonts found.");
    }
    return fonts;
  }

  /// Gets font from the list defined in case the above function doesn't work
  List<SystemFont> safelyGetSystemFonts() {
    try {
      return getSystemFonts();
    } catch (e) {
      List<List> defaultSystemFonts = [
        ["cursive", "DancingScript-Regular.ttf"],
        ["monospace", "DroidSansMono.ttf"],
        ["sans-serif", "Roboto-Regular.ttf"],
        ["sans-serif-light" "Roboto-Light.ttf"],
        ["sans-serif-medium", "Roboto-Medium.ttf"],
        ["sans-serif-black", "Roboto-Black.ttf"],
        ["sans-serif-condensed", "RobotoCondensed-Regular.ttf"],
        ["sans-serif-thin", "Roboto-Thin.ttf"],
        ["serif", "NotoSerif-Regular.ttf"]
      ];
      List<SystemFont> fonts = <SystemFont>[];
      for (List names in defaultSystemFonts) {
        File file = File('/system/fonts/${names[1]}');
        if (file.existsSync()) {
          fonts.add(SystemFont(names[0], file.path));
        }
      }
      return fonts;
    }
  }
}
