import 'package:rich_editor/src/models/enum.dart';

import 'command_state.dart';

class EditorState {
  bool? didHtmlChange;
  String? html;
  Map<CommandName, CommandState>? commandStates;

  EditorState({
    this.didHtmlChange = false,
    this.html = '',
    this.commandStates = const <CommandName, CommandState>{},
  });

  EditorState.fromJson(Map<String, dynamic> json) {
    didHtmlChange = json['didHtmlChange'];
    html = json['html'];
    commandStates = json['commandStates'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['didHtmlChange'] = this.didHtmlChange;
    data['html'] = this.html;
    data['commandStates'] = this.commandStates;
    return data;
  }
}

