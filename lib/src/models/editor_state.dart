import 'command_state.dart';
import 'enum/command_name.dart';

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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['didHtmlChange'] = didHtmlChange;
    data['html'] = html;
    data['commandStates'] = commandStates;
    return data;
  }
}
