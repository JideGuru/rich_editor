import 'package:flutter/material.dart';

/// An extension that makes it easy to get Hex code
/// from [Color] and [MaterialColor]
extension ColorX on Color {
  String toHexColorString() {
    String hex = value.toRadixString(16).replaceAll('ff', '');
    if(hex.isEmpty) hex = '000000';
    return '#$hex';
  }
}
