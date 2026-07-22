import 'package:bamabin_desktop/data/remote/model/videos/post.dart';

class PlayStatus {
  final Post post;
  final String remainingTime;
  final String currentTime;
  final String duration;
  final double watchPercentage;

  PlayStatus({
    required this.post,
    required this.remainingTime,
    required this.currentTime,
    required this.duration,
    required this.watchPercentage,
  });

  factory PlayStatus.fromJson(Map<String, dynamic> json) => PlayStatus(
    post: Post.fromJson(json),
    remainingTime: json['remaining_time']?.toString() ?? '',
    currentTime: json['current_time']?.toString() ?? '',
    duration: json['duration']?.toString() ?? '',
    watchPercentage: _asDouble(json['watch_percentage']),
  );

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
