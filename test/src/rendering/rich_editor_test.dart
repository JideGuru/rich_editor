import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_editor/rich_editor.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('rich editor ...', (tester) async {
    await binding.setSurfaceSize(Size(1080, 2280));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RichEditor(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(1, 1);

  }, variant: TargetPlatformVariant.mobile());
}