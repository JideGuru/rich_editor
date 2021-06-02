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
          fonts!.add(new Font.fromJson(v));
        });
      }
    }
    lang = json['lang'];
    variant = json['variant'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    if (this.fonts != null) {
      data['font'] = this.fonts!.map((v) => v.toJson()).toList();
    }
    data['lang'] = this.lang;
    data['variant'] = this.variant;
    return data;
  }
}
