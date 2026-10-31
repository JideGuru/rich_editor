import 'package:flutter/foundation.dart';

@immutable
class SystemFont {
  final String name;
  final String path;

  const SystemFont(this.name, this.path);

  @override
  bool operator ==(Object other) =>
      other is SystemFont && other.name == name && other.path == path;

  @override
  int get hashCode => Object.hash(name, path);

  @override
  String toString() => 'SystemFont($name, $path)';
}
