class Country {
  final String name;
  final String link;

  Country({required this.name, required this.link});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    name: json['name'] ?? '',
    link: json['link'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'link': link,
  };
}
