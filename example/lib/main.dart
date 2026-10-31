import 'package:example/basic_demo.dart';
import 'package:example/custom_toolbar_demo.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rich_editor demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const _DemoList(),
    );
  }
}

class _DemoList extends StatelessWidget {
  const _DemoList();

  @override
  Widget build(BuildContext context) {
    void open(Widget demo) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => demo));

    return Scaffold(
      appBar: AppBar(title: const Text('rich_editor demos')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Basic demo'),
            onTap: () => open(const BasicDemo()),
          ),
          ListTile(
            title: const Text('Custom toolbar demo'),
            onTap: () => open(const CustomToolbarDemo()),
          ),
        ],
      ),
    );
  }
}
