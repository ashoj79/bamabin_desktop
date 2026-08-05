import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';

/// Arguments passed when opening the player.
class PlayerArgs {
  const PlayerArgs({
    required this.data,
    required this.type,
    required this.season,
    required this.episode,
  });

  /// The post being played.
  final PostDetails data;

  /// Which download-box variant (dubbed/subtitle/native/screen) to play.
  final MovieType type;

  /// For series: the season index. For movies: the initial quality index
  /// (mirrors the mobile convention).
  final int season;

  /// For series: the episode index. For movies: usually 0/-1 (unused).
  final int episode;
}
