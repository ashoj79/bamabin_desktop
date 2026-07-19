import 'post.dart';
import 'country.dart';
import 'post_details.dart';

class SinglePost {
  final Post mainData;
  final String runtime;
  final String summary;
  final String title;
  final String type;
  final String postType;
  final List<Country> countries;
  final MovieDownloadBox? movieDownloadBox;
  final List<Season>? seasons;

  SinglePost({
    required this.mainData,
    required this.runtime,
    required this.summary,
    required this.title,
    required this.type,
    required this.postType,
    required this.countries,
    this.movieDownloadBox,
    this.seasons,
  });

  factory SinglePost.fromJson(Map<String, dynamic> json) => SinglePost(
    mainData: Post.fromJson(json),
    runtime: json['runtime_movie'] ?? '',
    summary: json['fa_plot_movie'] ?? '',
    title: json['title_movie'] ?? '',
    type: json['type'] ?? '',
    postType: json['post_type'] ?? '',
    countries: (json['countries'] as List?)
            ?.map((e) => Country.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    movieDownloadBox: json['movies_dlbox'] != null
        ? MovieDownloadBox.fromJson(json['movies_dlbox'])
        : null,
    seasons: json['series_dlbox'] != null
        ? (json['series_dlbox'] as List)
              .map((e) => Season.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
  );
}
