import 'package:flutter/material.dart';

class Request {
  final int id;
  final String title;
  final String postId;
  final String status;
  final String message;
  final String date;

  Request({
    required this.id,
    required this.title,
    required this.postId,
    required this.status,
    required this.message,
    required this.date,
  });

  factory Request.fromJson(Map<String, dynamic> json) => Request(
    id: int.tryParse(json['ID']) ?? 0,
    title: json['title'] ?? '',
    postId: json['post_id'] ?? '',
    status: json['status'] ?? '',
    message: json['message'] ?? '',
    date: json['created_at'] ?? '',
  );

  Color get statusColor {
    switch (status) {
      case 'رد شده':
        return Colors.red;
      case 'تایید شده':
        return Colors.green;
      default:
        return Colors.white;
    }
  }

  bool get isSubmitted => status == 'تایید شده';
}
