library rich_editor;


export 'src/models/enum/bar_position.dart';
export 'src/models/rich_editor_options.dart';
export 'src/utils/javascript_executor_base.dart';
export 'src/rendering/widgets/editor_tool_bar.dart';
export 'src/rendering/widgets/tab_button.dart';
export 'src/rendering/widgets/tab_button.dart';

export 'src/rendering/rich_editor_unsupported.dart'
  if (dart.library.html) 'src/rendering/rich_editor_web.dart'
  if (dart.library.io) 'src/rendering/rich_editor_mobile.dart';
