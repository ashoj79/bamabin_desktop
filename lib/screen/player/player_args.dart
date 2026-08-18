import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';

/// Arguments passed when opening the player.
class PlayerArgs {
  const PlayerArgs({
    required this.data,
    required this.type,
    required this.season,
    required this.episode,
    this.localFilePath,
  });

  factory PlayerArgs.localFile({
    required String filePath,
    required String title,
    String posterUrl = '',
  }) {
    return PlayerArgs(
      data: PostDetails(
        id: 0,
        title: title,
        faTitle: title,
        link: '',
        trailer: '',
        bgThumbnail: posterUrl,
        imdbRate: '',
        imdbVoteCount: 0,
        hasDubbed: false,
        hasSubtitle: false,
        years: const [],
        summary: '',
        postType: 'movies',
        status: '',
        movieStatus: '',
        updateText: '',
        ageRate: '',
        isInWatchlist: false,
        isFree: true,
        awardsSummary: '',
        top250movie: '',
        rotten: '',
        metacritic: '',
        mal: '',
        mdl: '',
        relatedPosts: const [],
        collectionPosts: const [],
        watchStatus: '',
        watchSeasonId: 1,
        watchEpisodeId: 1,
        time: 0,
        genresId: const [],
        type: 'movies',
      ),
      type: MovieType.subtitle,
      season: 0,
      episode: 0,
      localFilePath: filePath,
    );
  }

  /// The post being played.
  final PostDetails data;

  /// Which download-box variant (dubbed/subtitle/native/screen) to play.
  final MovieType type;

  /// For series: the season index. For movies: the initial quality index
  /// (mirrors the mobile convention).
  final int season;

  /// For series: the episode index. For movies: usually 0/-1 (unused).
  final int episode;

  /// When set, the player opens this local file instead of a network URL.
  final String? localFilePath;

  bool get isLocalPlayback =>
      localFilePath != null && localFilePath!.isNotEmpty;
}
