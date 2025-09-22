import 'package:flutter/material.dart';

/// An extension that makes it easy to get Hex code
/// from [Color] and [MaterialColor]
extension ColorX on Color {
  String toHexColorString() {
    String hex = (toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '#$hex';
  }
}
