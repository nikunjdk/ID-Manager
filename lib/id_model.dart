// To parse this JSON data, do
//
//     final idModel = idModelFromMap(jsonString);

import 'dart:convert';

IdModel idModelFromMap(String str) => IdModel.fromMap(json.decode(str));

String idModelToMap(IdModel data) => json.encode(data.toMap());

class IdModel {
  IdModel({
    this.name,
    this.id,
    this.type,
    this.imagePath,
  });

  String? name;
  String? id;
  String? type;
  String? imagePath;

  factory IdModel.fromMap(Map<String, dynamic> json) => IdModel(
        name: json["name"],
        id: json["id"],
        type: json["type"],
        imagePath: json["image path"],
      );

  Map<String, dynamic> toMap() => {
        "name": name,
        "id": id,
        "type": type,
        "image path": imagePath,
      };
}
