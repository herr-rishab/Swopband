// To parse this JSON data, do
//
//     final fetchAllLinksModel = fetchAllLinksModelFromJson(jsonString);

import 'dart:convert';

FetchAllLinksModel fetchAllLinksModelFromJson(String str) => FetchAllLinksModel.fromJson(json.decode(str));

String fetchAllLinksModelToJson(FetchAllLinksModel data) => json.encode(data.toJson());

class FetchAllLinksModel {
  List<Link> links;

  FetchAllLinksModel({
    required this.links,
  });

  factory FetchAllLinksModel.fromJson(Map<String, dynamic> json) => FetchAllLinksModel(
    links: List<Link>.from(json["links"].map((x) => Link.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "links": List<dynamic>.from(links.map((x) => x.toJson())),
  };
}

class Link {
  String id;
  String userId;
  String type;
  String url;

  Link({
    required this.id,
    required this.userId,
    required this.type,
    required this.url,
  });

  factory Link.fromJson(Map<String, dynamic> json) => Link(
    id: json["id"].toString(),
    userId: json["user_id"].toString(),
    type: json["type"].toString(),
    url: json["url"].toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "type": type,
    "url": url,
  };
}
