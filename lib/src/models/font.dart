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
      axis = json['axis'] != null ? Axis.fromJson(json['axis']) : null;
    }

    index = json['index'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['weight'] = weight;
    data['style'] = style;
    data[r'$t'] = t;
    data['fallbackFor'] = fallbackFor;
    if (axis != null) {
      data['axis'] = axis!.toJson();
    }
    data['index'] = index;
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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['tag'] = tag;
    data['stylevalue'] = stylevalue;
    return data;
  }
}
