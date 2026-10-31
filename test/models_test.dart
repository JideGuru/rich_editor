import 'package:flutter_test/flutter_test.dart';
import 'package:rich_editor/rich_editor.dart';

void main() {
  test('CommandState parses the editor JSON', () {
    expect(
      CommandState.fromJson({'enabled': true, 'active': true, 'value': 'h2'}),
      const CommandState(enabled: true, active: true, value: 'h2'),
    );
    expect(CommandState.fromJson({}), const CommandState());
  });

  test('RichEditorValue answers command queries', () {
    const value = RichEditorValue(commandStates: {
      EditorCommand.bold: CommandState(enabled: true, active: true),
      EditorCommand.formatBlock: CommandState(value: 'blockquote'),
    });
    expect(value.isActive(EditorCommand.bold), isTrue);
    expect(value.isActive(EditorCommand.italic), isFalse);
    expect(value.valueOf(EditorCommand.formatBlock), 'blockquote');
    expect(value.valueOf(EditorCommand.fontName), '');
  });

  test('RichEditorOptions compares by value', () {
    expect(
      const RichEditorOptions(
          placeholder: 'a', toolbarItems: [ToolbarItem.bold]),
      RichEditorOptions(placeholder: 'a', toolbarItems: [ToolbarItem.bold]),
    );
    expect(const RichEditorOptions(placeholder: 'a'),
        isNot(const RichEditorOptions(placeholder: 'b')));
  });

  group('RichEditorController', () {
    test('keeps HTML set before the editor is ready', () async {
      final controller = RichEditorController();
      await controller.setHtml('<p>early</p>');
      expect(controller.ready.value, isFalse);
      expect(controller.markReady(), '<p>early</p>');
      expect(controller.ready.value, isTrue);
      expect(controller.markReady(), isNull);
      controller.dispose();
    });

    test('detach makes it not ready again', () {
      final controller = RichEditorController()..markReady();
      controller.detach();
      expect(controller.ready.value, isFalse);
      expect(controller.executor.isReady, isFalse);
      controller.dispose();
    });
  });
}
