import 'dart:convert';

class Post {
  final int id;
  final String title;
  final String faTitle;
  final String thumbnail;
  final String bgThumbnail;
  final String imdbRate;
  final bool hasAudio;
  final List<int> genresId;
  final List<int> years;

  Post({
    required this.id,
    required this.title,
    required this.faTitle,
    required this.thumbnail,
    required this.bgThumbnail,
    required this.imdbRate,
    required this.hasAudio,
    required this.genresId,
    required this.years,
  });

  String get releaseYear => (years.isNotEmpty ? years[0] : 0).toString();

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] ?? 0,
    title: json['title'] ?? '',
    faTitle: json['fa_title'] ?? '',
    thumbnail: json['thumbnail'] ?? '',
    bgThumbnail: json['bg_thumbnail'] ?? '',
    imdbRate: json['imdb_rate'] != null ? json['imdb_rate'].toString() : '',
    hasAudio: json['has_dubbed'] ?? false,
    genresId:
        (json['genres_id'] as List?)?.map((e) => e as int).toList() ?? [],
    years: (json['years'] as List?)?.map((e) => e as int).toList() ?? [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'fa_title': faTitle,
    'thumbnail': thumbnail,
    'bg_thumbnail': bgThumbnail,
    'imdb_rate': imdbRate,
    'has_dubbed': hasAudio,
    'genres_id': genresId,
    'years': years,
  };

  String toJsonEncoded() => Uri.encodeComponent(jsonEncode(toJson()));

  static Post fromJsonString(String jsonString) =>
      Post.fromJson(jsonDecode(jsonString));
}
