import 'package:flutter/material.dart';

/// An extension that makes it easy to get CSS color strings
/// from [Color] and [MaterialColor]
extension ColorX on Color {
  /// `#rrggbb`, ignoring transparency.
  String toHexColorString() {
    String hex = (toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '#$hex';
  }

  /// `#rrggbb` for opaque colors, `rgba(r, g, b, a)` otherwise.
  String toCssColorString() {
    final argb = toARGB32();
    final alpha = argb >> 24 & 0xFF;
    if (alpha == 0xFF) return toHexColorString();

    final red = argb >> 16 & 0xFF;
    final green = argb >> 8 & 0xFF;
    final blue = argb & 0xFF;
    // Trim "0.500" to "0.5" and "0.000" to "0".
    final opacity = (alpha / 255)
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
    return 'rgba($red, $green, $blue, $opacity)';
  }
}

/// Parses the CSS colors the editor reports: `#rrggbb`, `rgb(r, g, b)`
/// and `rgba(r, g, b, a)`. Returns null for anything else.
Color? parseCssColor(String css) {
  final value = css.trim().toLowerCase();

  final hex = RegExp(r'^#([0-9a-f]{6})$').firstMatch(value);
  if (hex != null) {
    return Color(0xFF000000 | int.parse(hex.group(1)!, radix: 16));
  }

  final rgb = RegExp(
          r'^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)$')
      .firstMatch(value);
  if (rgb == null) return null;

  int channel(int group) => int.parse(rgb.group(group)!).clamp(0, 255);
  final alpha = double.tryParse(rgb.group(4) ?? '1') ?? 1;
  return Color.fromARGB(
    (alpha.clamp(0, 1) * 255).round(),
    channel(1),
    channel(2),
    channel(3),
  );
}
