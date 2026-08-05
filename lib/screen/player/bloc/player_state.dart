part of 'player_bloc.dart';

@immutable
sealed class PlayerBlocState {}

final class PlayerInitial extends PlayerBlocState {}

final class PlayerGetSubDefaultsSuccess extends PlayerBlocState {
  final int subTextColor, subBgColor, subFont, subSize, subMargin, videoSpeed;
  PlayerGetSubDefaultsSuccess({
    required this.subTextColor,
    required this.subBgColor,
    required this.subFont,
    required this.subSize,
    required this.subMargin,
    required this.videoSpeed,
  });
}

final class PlayerSaveWatchingEpisodeSuccess extends PlayerBlocState {
  final WatchingEpisode watchingEpisode;
  PlayerSaveWatchingEpisodeSuccess({required this.watchingEpisode});
}
