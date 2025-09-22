import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rich_editor/rich_editor.dart';

class BasicDemo extends StatefulWidget {
  const BasicDemo({super.key});

  @override
  State<BasicDemo> createState() => _BasicDemoState();
}

class _BasicDemoState extends State<BasicDemo> {
  GlobalKey<RichEditorState> keyEditor = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Demo'),
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
      body: RichEditor(
        key: keyEditor,
        value: '''
        Hello, This is a rich text Editor for Flutter. It supports most things like Bold, italics and underline.
        As well as Subscript, Superscript, Colored text, Colors bg text and hyperlink.
        Images and Videos are also supports
        ''', // initial HTML data
        editorOptions: RichEditorOptions(
          placeholder: 'Start typing',
          // backgroundColor: Colors.blueGrey, // Editor's bg color
          // baseTextColor: Colors.white,
          // editor padding
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          // font name
          baseFontFamily: 'sans-serif',
          // Position of the editing bar (BarPosition.top or BarPosition.bottom)
          barPosition: BarPosition.top,
        ),

        // You can return a Link (maybe you need to upload the image to your
        // storage before displaying in the editor or you can also use base64
        getImageUrl: (image) {
          String base64 = base64Encode(image.readAsBytesSync());
          String base64String = 'data:image/png;base64, $base64';
          return Future<String>.value(base64String);
        },
        getVideoUrl: (video) {
          String link = 'https://file-examples-com.github.io/uploads/2017/'
              '04/file_example_MP4_480_1_5MG.mp4';
          return Future<String>.value(link);
        },
        disableVideo: true,
        onDisabledVideoTap: () {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text('Video is disabled'),
                content: Text(
                    'Video is disabled, you tell the users to pay or something'),
              );
            },
          );
        },
      ),
    );
  }
}
