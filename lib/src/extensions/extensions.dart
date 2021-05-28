import 'package:flutter/material.dart';

extension ColorX on Color {
  String toHexColorString() => '#${value.toRadixString(16).replaceAll('ff', '')}';
}