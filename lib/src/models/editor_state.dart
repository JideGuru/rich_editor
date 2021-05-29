import 'package:rich_editor/src/models/enum.dart';

import 'command_state.dart';

class EditorState {
  bool didHtmlChange;
  String html;
  Map<CommandName, CommandState> commandStates;

  EditorState({
    this.didHtmlChange = false,
    this.html = '',
    this.commandStates = const <CommandName, CommandState>{},
  });
}
