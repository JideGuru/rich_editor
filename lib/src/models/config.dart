import 'package:rich_editor/src/models/alias.dart';

import 'family.dart';

class Config {
  String? version;
  List<Family>? families;
  List<Alias>? aliases;

  Config({this.version, this.families, this.aliases});

  Config.fromJson(Map<String, dynamic> json) {
    version = json['version'];
    if (json['family'] != null) {
      families = <Family>[];
      json['family'].forEach((v) {
        families!.add(Family.fromJson(v));
      });
    }
    if (json['alias'] != null) {
      aliases = <Alias>[];
      json['alias'].forEach((v) {
        aliases!.add(Alias.fromJson(v));
      });
    }
  }
}
