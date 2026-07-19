class UserList {
  final int id;
  String title, content;
  final String date;
  final List<int> itemsId;

  UserList({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.itemsId,
  });

  factory UserList.fromJson(Map<String, dynamic> json) => UserList(
    id: int.tryParse(json['ID']) ?? 0,
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    date: json['created_at'] ?? '',
    itemsId: (json['items_id'] as List?)
            ?.map((e) => e as int)
            .toList() ??
        [],
  );
}
