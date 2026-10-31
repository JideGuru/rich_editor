import 'package:flutter/material.dart';
import 'package:rich_editor/rich_editor.dart';

class CustomToolbarDemo extends StatefulWidget {
  const CustomToolbarDemo({super.key});

  @override
  State<CustomToolbarDemo> createState() => _CustomToolbarDemoState();
}

class _CustomToolbarDemoState extends State<CustomToolbarDemo> {
  final _controller = RichEditorController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final executor = _controller.executor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Toolbar Demo'),
        actions: [
          IconButton(
            tooltip: 'Print HTML',
            icon: const Icon(Icons.code),
            onPressed: () async =>
                debugPrint('Current HTML: ${await _controller.getHtml()}'),
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.clear_all),
            onPressed: _controller.clear,
          ),
        ],
      ),
      body: Column(
        children: [
          // Rebuilds as the cursor moves, so buttons reflect the formatting
          // at the cursor.
          ValueListenableBuilder<RichEditorValue>(
            valueListenable: _controller,
            builder: (context, value, _) => Wrap(
              children: [
                TabButton(
                  tooltip: 'Bold',
                  icon: Icons.format_bold,
                  selected: value.isActive(EditorCommand.bold),
                  onTap: executor.setBold,
                ),
                TabButton(
                  tooltip: 'Italic',
                  icon: Icons.format_italic,
                  selected: value.isActive(EditorCommand.italic),
                  onTap: executor.setItalic,
                ),
                TabButton(
                  tooltip: 'Heading',
                  icon: Icons.title,
                  selected: value.valueOf(EditorCommand.formatBlock) == 'h2',
                  onTap: () => executor.setHeading(2),
                ),
              ],
            ),
          ),
          Expanded(
            child: RichEditor(
              controller: _controller,
              editorOptions: const RichEditorOptions(
                placeholder: 'Start typing',
                padding: EdgeInsets.symmetric(horizontal: 5.0),
                baseFontFamily: 'sans-serif',
                // The built-in toolbar is replaced by the one above.
                barPosition: BarPosition.custom,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
