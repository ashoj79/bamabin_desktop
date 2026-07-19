class LikeInfo {
  final int likes;
  final int dislikes;
  final double percent;

  LikeInfo({
    required this.likes,
    required this.dislikes,
    required this.percent,
  });

  factory LikeInfo.fromJson(Map<String, dynamic> json) => LikeInfo(
    likes: json['likes'] ?? 0,
    dislikes: json['dislikes'] ?? 0,
    percent: (json['like_percent'] ?? 0).toDouble(),
  );
}
