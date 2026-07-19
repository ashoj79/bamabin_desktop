class Notification {
  final String title;
  final String content;
  /// Minutes since the notification was sent.
  final int diffTime;
  final bool isNew;

  Notification({
    required this.title,
    required this.content,
    this.diffTime = 0,
    this.isNew = false,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    diffTime: (json['diff_time'] as num?)?.toInt() ?? 0,
    isNew: json['is_new'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'diff_time': diffTime,
    'is_new': isNew,
  };
}
