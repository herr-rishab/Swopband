// To parse this JSON data, do
//
//     final connectionsModel = connectionsModelFromJson(jsonString);

import 'dart:convert';

ConnectionsModel connectionsModelFromJson(String str) => ConnectionsModel.fromJson(json.decode(str));

String connectionsModelToJson(ConnectionsModel data) => json.encode(data.toJson());

class ConnectionsModel {
  List<Connection> connections;

  ConnectionsModel({
    required this.connections,
  });

  factory ConnectionsModel.fromJson(Map<String, dynamic> json) => ConnectionsModel(
    connections: List<Connection>.from(json["connections"].map((x) => Connection.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "connections": List<dynamic>.from(connections.map((x) => x.toJson())),
  };
}

class Connection {
  String id;
  String userId;
  String connectionUid;
  String createdAt;
  String updatedAt;

  Connection({
    required this.id,
    required this.userId,
    required this.connectionUid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    return Connection(
      id: json["id"].toString(),
      userId: json["user_id"].toString(),
      connectionUid: json["connection_uid"].toString(),
      createdAt: json["created_at"].toString(),
      updatedAt: json["updated_at"].toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "user_id": userId,
    "connection_uid": connectionUid,
    "created_at": createdAt,
    "updated_at": updatedAt,
  };
}

// User Details Model
UserDetailsModel userDetailsModelFromJson(String str) => UserDetailsModel.fromJson(json.decode(str));

String userDetailsModelToJson(UserDetailsModel data) => json.encode(data.toJson());

class UserDetailsModel {
  User user;

  UserDetailsModel({
    required this.user,
  });

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) => UserDetailsModel(
    user: User.fromJson(json["user"]),
  );

  Map<String, dynamic> toJson() => {
    "user": user.toJson(),
  };
}

class User {
  String id;
  String firebaseId;
  String username;
  String? bio;
  String? profileUrl;
  String name;
  String? age;
  String email;
  String createdAt;
  String updatedAt;
  String? connectionId; // Store connection ID for removal

  User({
    required this.id,
    required this.firebaseId,
    required this.username,
    this.bio,
    this.profileUrl,
    required this.name,
    this.age,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.connectionId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["id"].toString(),
      firebaseId: json["firebase_id"].toString(),
      username: json["username"].toString(),
      bio: json["bio"],
      profileUrl: json["profile_url"],
      name: json["name"].toString(),
      age: json["age"]?.toString(), // Convert to string if it's an integer
      email: json["email"].toString(),
      createdAt: json["created_at"].toString(),
      updatedAt: json["updated_at"].toString(),
      connectionId: json["connection_id"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "firebase_id": firebaseId,
    "username": username,
    "bio": bio,
    "profile_url": profileUrl,
    "name": name,
    "age": age,
    "email": email,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "connection_id": connectionId,
  };
}
