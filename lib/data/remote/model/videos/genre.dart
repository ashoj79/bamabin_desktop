class Genre {
  final int id;
  final String name;
  final String link;
  final String icon;
  final String backgroundUrl;
  final int count;

  Genre({
    required this.id,
    required this.name,
    required this.link,
    required this.icon,
    required this.backgroundUrl,
    required this.count,
  });

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    link: json['link'] ?? '',
    icon: json['icon'] ?? '',
    backgroundUrl: json['background_url'] ?? '',
    count: json['count'] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'link': link,
    'icon': icon,
    'background_url': backgroundUrl,
    'count': count,
  };
}
