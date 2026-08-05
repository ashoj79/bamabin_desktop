import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:bamabin_desktop/data/local/database/model/watching_episode.dart';
import 'package:bamabin_desktop/repository/app_repository.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerBlocState> {
  final AppRepository _appRepository;
  final VideoRepository _videoRepository;

  PlayerBloc(this._appRepository, this._videoRepository)
      : super(PlayerInitial()) {
    on<PlayerGetSubDefaultsEvent>((event, emit) async {
      final subTextColor = await _appRepository.getSubTextColor();
      final subBgColor = await _appRepository.getSubBgColor();
      final subFont = await _appRepository.getSubFont();
      final subSize = await _appRepository.getSubSize();
      final subMargin = await _appRepository.getSubMargin();
      final videoSpeed = await _appRepository.getVideoSpeed();
      emit(
        PlayerGetSubDefaultsSuccess(
          subTextColor: subTextColor,
          subBgColor: subBgColor,
          subFont: subFont,
          subSize: subSize,
          subMargin: subMargin,
          videoSpeed: videoSpeed,
        ),
      );
    });

    on<PlayerSetSubDefaultsEvent>((event, emit) async {
      if (event.subTextColor != null) {
        await _appRepository.setSubTextColor(event.subTextColor!);
      }
      if (event.subBgColor != null) {
        await _appRepository.setSubBgColor(event.subBgColor!);
      }
      if (event.subFont != null) {
        await _appRepository.setSubFont(event.subFont!);
      }
      if (event.subSize != null) {
        await _appRepository.setSubSize(event.subSize!);
      }
      if (event.subMargin != null) {
        await _appRepository.setSubMargin(event.subMargin!);
      }
      if (event.videoSpeed != null) {
        await _appRepository.setVideoSpeed(event.videoSpeed!);
      }
    });

    on<PlayerSaveWatchingEpisodeEvent>((event, emit) async {
      if (event.isNew) {
        await _videoRepository.saveWatchingEpisode(event.watchingEpisode);
      } else {
        await _videoRepository.updateWatchingEpisode(event.watchingEpisode);
      }
      final watchingEpisode = await _videoRepository.getWatchingEpisode(
            event.watchingEpisode.id,
            event.watchingEpisode.season,
            event.watchingEpisode.episode,
          ) ??
          event.watchingEpisode;
      emit(PlayerSaveWatchingEpisodeSuccess(watchingEpisode: watchingEpisode));
    });

    on<PlayerDeleteWatchDataEvent>((event, emit) async {
      await _videoRepository.deleteWatchDataWithId(event.id);
    });
  }
}
