import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rich_editor/rich_editor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Rich Editor Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey<RichEditorState> keyEditor = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton(
            child: IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: null,
              disabledColor: Colors.white,
            ),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  child: Text('Get HTML'),
                  value: 0,
                ),
                PopupMenuItem(
                  child: Text('Clear content'),
                  value: 1,
                ),
                PopupMenuItem(
                  child: Text('Hide keyboard'),
                  value: 2,
                ),
                PopupMenuItem(
                  child: Text('Show Keyboard'),
                  value: 3,
                ),
              ];
            },
            onSelected: (val) async {
              switch (val) {
                case 0:
                  String? html = await keyEditor.currentState?.getHtml();
                  print(html);
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
//         value: '''
//         <h1>Heading 1</h1>
// <h2>Heading 2</h2>
// <h3>Heading 3</h3>
// <h4>Heading 4</h4>
// <h5>Heading 5</h5>
// <h6>Heading 6</h6>
//         ''', // initial HTML data
        placeholder: 'Start typing',
        // backgroundColor: Colors.blueGrey, // Editor's bg color
        // baseTextColor: Colors.white,
        // editor padding
        padding: EdgeInsets.symmetric(horizontal: 5.0),
        // font name
        baseFontFamily: 'sans-serif',
        // Position of the editing bar (BarPosition.TOP or BarPosition.BOTTOM)
        barPosition: BarPosition.TOP,
        // You can return a Link (maybe you need to upload the image to your
        // storage before displaying in the editor or you can also use base64
        getImageUrl: (image) {
          String link = 'https://avatars.githubusercontent.com/u/24323581?v=4';
          String base64 = base64Encode(image.readAsBytesSync());
          String base64String = 'data:image/png;base64, $base64';
          return base64String;
        },
      ),
    );
  }
}
