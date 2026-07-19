class Gateway {
  final int id;
  final String slug;
  final String name;
  final String icon;
  final String type;

  Gateway({
    required this.id,
    required this.slug,
    required this.name,
    required this.icon,
    required this.type,
  });

  factory Gateway.fromJson(Map<String, dynamic> json) => Gateway(
    id: int.tryParse(json['id']) ?? 0,
    slug: json['slug'] ?? '',
    name: json['name'] ?? '',
    icon: json['icon'] ?? '',
    type: json['type'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'icon': icon,
    'type': type,
  };
}
