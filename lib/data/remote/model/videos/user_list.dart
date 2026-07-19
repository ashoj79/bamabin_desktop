import 'package:bamabin_desktop/data/remote/model/user/user_data.dart';
import 'dart:convert';

class UserList {
  final int id;
  final String title;
  final String createdAt;
  final List<String> thumbnails;
  final int postsCount;
  final UserData user;

  UserList({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.thumbnails,
    required this.postsCount,
    required this.user,
  });

  factory UserList.fromJson(Map<String, dynamic> json) => UserList(
    id: int.parse(json['ID'] ?? '0'),
    title: json['title'] ?? '',
    createdAt: json['created_at'] ?? '',
    thumbnails:
        (json['thumbnails'] as List?)?.map((e) => e as String).toList() ?? [],
    postsCount: json['posts_count'] ?? 0,
    user: UserData.fromJson(json['user'] ?? {}),
  );

  static UserList fromJsonString(String jsonString) =>
      UserList.fromJson(jsonDecode(jsonString));
}
