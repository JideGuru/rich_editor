import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rich_editor/rich_editor.dart';

class CustomToolbarDemo extends StatefulWidget {
  const CustomToolbarDemo({super.key});

  @override
  State<CustomToolbarDemo> createState() => _CustomToolbarDemoState();
}

class _CustomToolbarDemoState extends State<CustomToolbarDemo> {
  GlobalKey<RichEditorState> keyEditor = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Toolbar Demo'),
        actions: [
          PopupMenuButton(
            child: const IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: null,
              disabledColor: Colors.white,
            ),
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 0,
                  child: Text('Get HTML'),
                ),
                const PopupMenuItem(
                  value: 1,
                  child: Text('Clear content'),
                ),
                const PopupMenuItem(
                  value: 2,
                  child: Text('Hide keyboard'),
                ),
                const PopupMenuItem(
                  value: 3,
                  child: Text('Show Keyboard'),
                ),
              ];
            },
            onSelected: (val) async {
              switch (val) {
                case 0:
                  String? html = await keyEditor.currentState?.getHtml();
                  debugPrint('Current HTML: $html');
                  break;
                case 1:
                  await keyEditor.currentState?.clear();
                  break;
                case 2:
                  await keyEditor.currentState?.unFocus();
                  break;
                case 3:
                  await keyEditor.currentState?.focus();
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Wrap(
            children: [
              IconButton(
                icon: const Icon(Icons.format_bold),
                onPressed: () {
                  keyEditor.currentState!.javascriptExecutor.setBold();
                },
              ),
            ],
          ),
          Expanded(
            child: RichEditor(
              key: keyEditor,
//         value: '', // initial HTML data
              editorOptions: RichEditorOptions(
                placeholder: 'Start typing',
                // backgroundColor: Colors.blueGrey, // Editor's bg color
                // baseTextColor: Colors.white,
                // editor padding
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                // font name
                baseFontFamily: 'sans-serif',
                // Position of the editing bar (BarPosition.top or BarPosition.bottom)
                barPosition: BarPosition.custom,
              ),

              // You can return a Link (maybe you need to upload the image to your
              // storage before displaying in the editor or you can also use base64
              getImageUrl: (image) {
                String base64 = base64Encode(image.readAsBytesSync());
                String base64String = 'data:image/png;base64, $base64';
                return Future<String>.value(base64String);
              },
            ),
          ),
        ],
      ),
    );
  }
}
