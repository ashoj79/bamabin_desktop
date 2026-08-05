part of 'player_bloc.dart';

@immutable
sealed class PlayerEvent {}

class PlayerGetSubDefaultsEvent extends PlayerEvent {}

class PlayerSetSubDefaultsEvent extends PlayerEvent {
  final int? subTextColor, subBgColor, subFont, subSize, subMargin, videoSpeed;
  PlayerSetSubDefaultsEvent({
    this.subTextColor,
    this.subBgColor,
    this.subFont,
    this.subSize,
    this.subMargin,
    this.videoSpeed,
  });
}

class PlayerSaveWatchingEpisodeEvent extends PlayerEvent {
  final WatchingEpisode watchingEpisode;
  final bool isNew;
  PlayerSaveWatchingEpisodeEvent({
    required this.watchingEpisode,
    required this.isNew,
  });
}

class PlayerDeleteWatchDataEvent extends PlayerEvent {
  final int id;
  PlayerDeleteWatchDataEvent({required this.id});
}
