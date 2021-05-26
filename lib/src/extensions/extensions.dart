import 'package:flutter/material.dart';

extension ColorX on Color {
  String toHexColorString() => '#${value.toString().replaceAll('ColorSwatch(',
      '').replaceAll('Color(0xff', '').replaceAll('MaterialColor(', '')
      .replaceAll('MaterialAccentColor(', '').replaceAll('primary value: '
      'Color(0xff', '').replaceAll('primary', '').replaceAll('value:', '')
      .replaceAll(')', '').trim()}';
}