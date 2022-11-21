import 'package:flutter/material.dart';

class Platform {
  static bool isIos(BuildContext context) => Theme.of(context).platform == TargetPlatform.iOS;
  static bool isAndroid(BuildContext context) => Theme.of(context).platform == TargetPlatform.android;
}