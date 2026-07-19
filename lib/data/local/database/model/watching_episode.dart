import 'package:floor/floor.dart';

@entity
class WatchingEpisode {
  WatchingEpisode({
    this.pk,
    required this.id,
    required this.season,
    required this.episode,
    required this.time,
    required this.duration,
    required this.type,
  });

  @PrimaryKey(autoGenerate: true)
  final int? pk;
  final int id;
  final int season;
  final int episode;
  final int time;
  final int duration;
  final String type;
}
