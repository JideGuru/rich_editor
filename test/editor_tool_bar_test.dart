import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rich_editor/rich_editor.dart';

class _RecordingExecutor extends JavascriptExecutorBase {
  final List<String> commands = [];

  @override
  Future<Object?> executeJavascript(String command) async {
    commands.add(command);
    return null;
  }
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late _RecordingExecutor executor;

  setUp(() => executor = _RecordingExecutor());

  testWidgets('shows a loading row until the editor is loaded', (tester) async {
    await tester.pumpWidget(_app(EditorToolBar(javascriptExecutor: executor)));
    expect(find.text('Loading editor...'), findsOneWidget);
    expect(find.byType(TabButton), findsNothing);
  });

  testWidgets('shows only the chosen items, in order', (tester) async {
    await tester.pumpWidget(_app(EditorToolBar(
      javascriptExecutor: executor,
      isWebViewLoaded: true,
      items: const [ToolbarItem.undo, ToolbarItem.bold],
    )));

    final buttons = tester.widgetList<TabButton>(find.byType(TabButton));
    expect(buttons.map((b) => b.tooltip), ['Undo', 'Bold']);

    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.tap(find.byIcon(Icons.undo));
    expect(executor.commands, ['setBold();', 'undo();']);
  });

  testWidgets('highlights active formatting', (tester) async {
    await tester.pumpWidget(_app(EditorToolBar(
      javascriptExecutor: executor,
      isWebViewLoaded: true,
      items: const [
        ToolbarItem.bold,
        ToolbarItem.italic,
        ToolbarItem.textFormat,
        ToolbarItem.blockquote,
      ],
      commandStates: const {
        EditorCommand.bold: CommandState(active: true),
        EditorCommand.formatBlock: CommandState(value: 'h2'),
      },
    )));

    final selected = {
      for (final b in tester.widgetList<TabButton>(find.byType(TabButton)))
        b.tooltip: b.selected,
    };
    expect(selected, {
      'Bold': true,
      'Italic': false,
      'Font format': true,
      'Blockquote': false,
    });
  });

  testWidgets('uses custom labels', (tester) async {
    await tester.pumpWidget(_app(EditorToolBar(
      javascriptExecutor: executor,
      isWebViewLoaded: true,
      items: const [ToolbarItem.bold],
      labels: const RichEditorLabels(bold: 'Fett'),
    )));
    expect(tester.widget<TabButton>(find.byType(TabButton)).tooltip, 'Fett');
  });

  testWidgets('a disabled video button reports taps instead of opening',
      (tester) async {
    var disabledTaps = 0;
    await tester.pumpWidget(_app(EditorToolBar(
      javascriptExecutor: executor,
      isWebViewLoaded: true,
      items: const [ToolbarItem.video],
      disableVideo: true,
      onDisabledVideoTap: () => disabledTaps++,
    )));

    expect(tester.widget<TabButton>(find.byType(TabButton)).disabled, isTrue);
    await tester.tap(find.byType(TabButton));
    await tester.pumpAndSettle();
    expect(disabledTaps, 1);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('inserts a link from the dialog', (tester) async {
    await tester.pumpWidget(_app(EditorToolBar(
      javascriptExecutor: executor,
      isWebViewLoaded: true,
      items: const [ToolbarItem.link],
    )));

    await tester.tap(find.byType(TabButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, ' https://e.com ');
    await tester.enterText(find.byType(TextField).last, "it's");
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(executor.commands, ['insertLink("https://e.com", "it\'s");']);
  });

  testWidgets('a failed upload is reported and nothing is inserted',
      (tester) async {
    Object? reported;
    await tester.pumpWidget(_app(EditorToolBar(
      javascriptExecutor: executor,
      isWebViewLoaded: true,
      items: const [ToolbarItem.image],
      getImageUrl: (File _) async => throw Exception('offline'),
      onUploadError: (error, _) => reported = error,
    )));

    // Simulate what the dialog returns for a picked file.
    final toolbarContext = tester.element(find.byType(TabButton));
    await tester.tap(find.byType(TabButton));
    await tester.pumpAndSettle();
    Navigator.of(toolbarContext).pop<({String url, String alt, bool picked})>(
        (url: '/tmp/picked.png', alt: '', picked: true));
    await tester.pumpAndSettle();

    expect(reported, isA<Exception>());
    expect(executor.commands, isEmpty);
  });
}
