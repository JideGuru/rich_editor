import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rich_editor/rich_editor.dart';

class BasicDemo extends StatefulWidget {
  const BasicDemo({super.key});

  @override
  State<BasicDemo> createState() => _BasicDemoState();
}

class _BasicDemoState extends State<BasicDemo> {
  final _controller = RichEditorController();
  bool _readOnly = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Demo'),
        actions: [
          IconButton(
            tooltip: _readOnly ? 'Edit' : 'Read only',
            icon: Icon(_readOnly ? Icons.edit : Icons.lock_outline),
            onPressed: () => setState(() => _readOnly = !_readOnly),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) {
              return const [
                PopupMenuItem(value: 0, child: Text('Get HTML')),
                PopupMenuItem(value: 5, child: Text('Get text')),
                PopupMenuItem(value: 1, child: Text('Set HTML')),
                PopupMenuItem(value: 2, child: Text('Clear content')),
                PopupMenuItem(value: 3, child: Text('Hide keyboard')),
                PopupMenuItem(value: 4, child: Text('Show Keyboard')),
              ];
            },
            onSelected: (val) async {
              switch (val) {
                case 0:
                  final html = await _controller.getHtml();
                  debugPrint('Current HTML: $html');
                case 1:
                  await _controller.setHtml('<p>Replaced <b>content</b></p>');
                case 2:
                  await _controller.clear();
                case 3:
                  await _controller.unFocus();
                case 4:
                  await _controller.focus();
                case 5:
                  final text = await _controller.getText();
                  debugPrint('Current text: $text');
              }
            },
          ),
        ],
      ),
      body: RichEditor(
        controller: _controller,
        readOnly: _readOnly,
        // initial HTML data
        value: '''
        <p>Hello, This is a rich text Editor for Flutter. It supports most things like Bold, italics and underline.</p>
        <p>As well as Subscript, Superscript, Colored text, Colors bg text and hyperlink.</p>
        <p>Images and Videos are also supported</p>
        <img src="https://lh3.googleusercontent.com/d/1MZDHszaj2_7KZ7Q6VqttSzUkIuKxC-4a" width="300" height="300">
        ''',
        editorOptions: const RichEditorOptions(
          placeholder: 'Start typing',
          // backgroundColor: Colors.blueGrey, // Editor's bg color
          // baseTextColor: Colors.white,
          // editor padding
          padding: EdgeInsets.symmetric(horizontal: 5.0),
          // font name
          baseFontFamily: 'sans-serif',
          // Position of the editing bar (BarPosition.top or BarPosition.bottom)
          barPosition: BarPosition.top,
        ),
        onChanged: (html) => debugPrint('Changed: ${html.length} characters'),

        // You can return a Link (maybe you need to upload the image to your
        // storage before displaying in the editor or you can also use base64
        getImageUrl: (image) async {
          String base64 = base64Encode(await image.readAsBytes());
          return 'data:image/png;base64,$base64';
        },
        getVideoUrl: (video) async {
          return 'https://file-examples-com.github.io/uploads/2017/'
              '04/file_example_MP4_480_1_5MG.mp4';
        },
        onUploadError: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $error')),
          );
        },
        disableVideo: true,
        onDisabledVideoTap: () {
          showDialog<void>(
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
