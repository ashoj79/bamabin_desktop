import 'post.dart';

class WatchStatusPosts {
  final List<Post> notWatched;
  final List<Post> watching;
  final List<Post> watched;

  WatchStatusPosts({
    this.notWatched = const [],
    this.watching = const [],
    this.watched = const [],
  });

  factory WatchStatusPosts.fromJson(Map<String, dynamic> json) =>
      WatchStatusPosts(
        notWatched: (json['not_watched'] as List?)
                ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        watching: (json['watching'] as List?)
                ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        watched: (json['watched'] as List?)
                ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
