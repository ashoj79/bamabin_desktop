class TicketReply {
  final String content;
  final String type;
  final String? createdAt;
  final String? authorName;

  TicketReply({
    required this.content,
    required this.type,
    this.createdAt,
    this.authorName,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) => TicketReply(
        content: json['content']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ??
            json['date']?.toString() ??
            json['time']?.toString(),
        authorName: json['name']?.toString() ??
            json['author']?.toString() ??
            json['username']?.toString() ??
            json['user_name']?.toString(),
      );

  bool get isFromSupport {
    final t = type.toLowerCase().trim();
    if (t.isEmpty) return false;
    if (t == 'user' || t == 'customer' || t == 'client') return false;
    return t.contains('admin') ||
        t.contains('support') ||
        t.contains('staff') ||
        t.contains('agent') ||
        t.contains('پشتیبان') ||
        t == 'admin_reply' ||
        t == '1';
  }

  Map<String, dynamic> toJson() => {
        'content': content,
        'type': type,
        if (createdAt != null) 'created_at': createdAt,
        if (authorName != null) 'name': authorName,
      };
}
