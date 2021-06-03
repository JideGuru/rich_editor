import 'dart:convert';

import 'package:example/basic.dart';
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
      home: BasicDemo(),
    );
  }
}
