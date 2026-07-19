import 'post.dart';

class SearchResult {
  final List<Post> series;
  final List<Post> movies;
  final List<Post> animations;
  final List<Post> anime;

  SearchResult({
    this.series = const [],
    this.movies = const [],
    this.animations = const [],
    this.anime = const [],
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    series: (json['series'] as List?)
            ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    movies: (json['movies'] as List?)
            ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    animations: (json['animations'] as List?)
            ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    anime: (json['anime'] as List?)
            ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
