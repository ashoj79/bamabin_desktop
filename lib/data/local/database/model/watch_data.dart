import 'package:floor/floor.dart';

@entity
class WatchData {
  WatchData({
    this.pk,
    required this.id,
    required this.type,
    required this.quality,
    required this.qualityCode,
    required this.time,
    required this.duration,
    this.season = -1,
    this.episode = -1,
    this.audioTrack = -1,
    this.subtitleTrack = -1,
    this.updatedAt = 0,
  });

  @PrimaryKey(autoGenerate: true)
  final int? pk;
  final int id;
  final String type;
  final String quality;
  final String qualityCode;
  final int time;
  final int duration;
  final int season;
  final int episode;
  final int audioTrack;
  final int subtitleTrack;
  int updatedAt;
  bool isSavedRemotely = false;
}
