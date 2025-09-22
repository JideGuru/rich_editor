class Alias {
  String? name;
  String? to;
  String? weight;

  Alias({this.name, this.to, this.weight});

  Alias.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    to = json['to'];
    weight = json['weight'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['to'] = to;
    data['weight'] = weight;
    return data;
  }
}
