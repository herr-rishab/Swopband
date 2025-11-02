// To parse this JSON data, do
//
//     final faqListModel = faqListModelFromJson(jsonString);

import 'dart:convert';

FaqListModel faqListModelFromJson(String str) => FaqListModel.fromJson(json.decode(str));

String faqListModelToJson(FaqListModel data) => json.encode(data.toJson());

class FaqListModel {
  List<Faq> faq;

  FaqListModel({
    required this.faq,
  });

  factory FaqListModel.fromJson(Map<String, dynamic> json) => FaqListModel(
    faq: List<Faq>.from(json["faq"].map((x) => Faq.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "faq": List<dynamic>.from(faq.map((x) => x.toJson())),
  };
}

class Faq {
  String id;
  String question;
  String answer;
  String createdAt;
  String updatedAt;

  Faq({
    required this.id,
    required this.question,
    required this.answer,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
    id: json["id"].toString(),
    question: json["question"].toString(),
    answer: json["answer"].toString(),
    createdAt: json["created_at"].toString(),
    updatedAt: json["updated_at"].toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "question": question,
    "answer": answer,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}
