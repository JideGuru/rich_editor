class Font {
  String? weight;
  String? style;
  String? t;
  String? fallbackFor;
  Axis? axis;
  String? index;

  Font(
      {this.weight,
      this.style,
      this.t,
      this.fallbackFor,
      this.axis,
      this.index});

  Font.fromJson(Map<String, dynamic> json) {
    weight = json['weight'];
    style = json['style'];
    t = json[r'$t'];
    fallbackFor = json['fallbackFor'];
    if (json['axis'] is Map) {
      axis = json['axis'] != null ? new Axis.fromJson(json['axis']) : null;
    }

    index = json['index'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['weight'] = this.weight;
    data['style'] = this.style;
    data[r'$t'] = this.t;
    data['fallbackFor'] = this.fallbackFor;
    if (this.axis != null) {
      data['axis'] = this.axis!.toJson();
    }
    data['index'] = this.index;
    return data;
  }
}

class Axis {
  String? tag;
  String? stylevalue;

  Axis({this.tag, this.stylevalue});

  Axis.fromJson(Map<String, dynamic> json) {
    tag = json['tag'];
    stylevalue = json['stylevalue'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tag'] = this.tag;
    data['stylevalue'] = this.stylevalue;
    return data;
  }
}
