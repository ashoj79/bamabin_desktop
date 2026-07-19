class Taxonomy {
  final int id;
  final String name;

  Taxonomy({required this.id, required this.name});

  factory Taxonomy.fromJson(Map<String, dynamic> json) => Taxonomy(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}
