class Department {
  final int id;
  final String name;

  Department({required this.id, required this.name});

  factory Department.fromJson(Map<String, dynamic> json) => Department(
    id: int.parse(json['ID']),
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'ID': id,
    'name': name,
  };
}
