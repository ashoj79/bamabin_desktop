import 'dart:convert';

class Ticket {
  final int id;
  final String? title;
  final int department;
  final String statusName;
  final String createdAt;
  final String updatedAt;
  String? departmentName;

  Ticket({
    required this.id,
    this.title,
    required this.department,
    required this.statusName,
    required this.createdAt,
    required this.updatedAt,
    this.departmentName,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: int.tryParse(json['ID']) ?? 0,
    title: json['title'],
    department: int.tryParse(json['department']) ?? 0,
    statusName: json['status_name'] ?? '',
    createdAt: json['created_at'] ?? '',
    updatedAt: json['updated_at'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'ID': id,
    'title': title,
    'department': department,
    'status_name': statusName,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'departmentName': departmentName,
  };

  String toJsonEncoded() => Uri.encodeComponent(jsonEncode(toJson()));

  static Ticket fromJsonString(String jsonString) =>
      Ticket.fromJson(jsonDecode(jsonString));
}
