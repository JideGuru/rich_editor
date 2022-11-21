import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_editor/rich_editor.dart';

void main() {
  testWidgets('rich editor ...', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(1, 1);
  
    debugDefaultTargetPlatformOverride = null;
  });
}