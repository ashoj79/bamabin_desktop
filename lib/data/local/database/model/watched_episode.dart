import 'package:floor/floor.dart';

@entity
class WatchedEpisode {
  WatchedEpisode({
    this.pk,
    required this.id,
    required this.season,
    required this.episode,
    this.type = 'subtitle',
    this.time = 0,
  });

  @PrimaryKey(autoGenerate: true)
  final int? pk;
  final int id;
  final int season;
  final int episode;
  final String type;
  int time;
}
