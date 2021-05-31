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
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['to'] = this.to;
    data['weight'] = this.weight;
    return data;
  }
}