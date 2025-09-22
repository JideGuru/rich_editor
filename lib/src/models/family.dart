import 'font.dart';

class Family {
  String? name;
  List<Font>? fonts;
  String? lang;
  String? variant;

  Family({this.name, this.fonts, this.lang, this.variant});

  Family.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    if (json['font'] != null) {
      fonts = <Font>[];
      if (json['font'] is List) {
        json['font'].forEach((v) {
          fonts!.add(Font.fromJson(v));
        });
      }
    }
    lang = json['lang'];
    variant = json['variant'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (fonts != null) {
      data['font'] = fonts!.map((v) => v.toJson()).toList();
    }
    data['lang'] = lang;
    data['variant'] = variant;
    return data;
  }
}
