class TicketReply {
  final String content;
  final String type;

  TicketReply({required this.content, required this.type});

  factory TicketReply.fromJson(Map<String, dynamic> json) => TicketReply(
    content: json['content'] ?? '',
    type: json['type'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'content': content,
    'type': type,
  };
}
