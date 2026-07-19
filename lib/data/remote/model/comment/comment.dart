import '../videos/like_info.dart';

class Comment {
  final int id;
  final String content;
  final String author;
  final String avatar;
  final LikeInfo likeInfo;
  final bool hasSpoil;
  final int parentId;
  final String date;

  Comment({
    required this.id,
    required this.content,
    required this.author,
    required this.avatar,
    required this.likeInfo,
    required this.hasSpoil,
    required this.parentId,
    required this.date,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] != null ? int.parse(json['id']) : 0,
    content: json['content'] ?? '',
    author: json['author'] ?? '',
    avatar: json['avatar'] ?? '',
    likeInfo: LikeInfo.fromJson(json['like_info'] ?? {}),
    hasSpoil: json['hasSpoil'] ?? false,
    parentId: json['parent_id'] != null ? int.parse(json['parent_id']) : 0,
    date: json['converted_created_at'] ?? '',
  );
}
