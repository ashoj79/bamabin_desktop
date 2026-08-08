import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'top250_event.dart';
part 'top250_state.dart';

enum Top250Type { movies, series }

class Top250Bloc extends Bloc<Top250Event, Top250State> {
  Top250Bloc(this._videoRepository, this.type) : super(Top250Initial()) {
    on<Top250LoadEvent>(_onLoad);
  }

  final VideoRepository _videoRepository;
  final Top250Type type;

  Future<void> _onLoad(
    Top250LoadEvent event,
    Emitter<Top250State> emit,
  ) async {
    emit(Top250Loading());
    final result = type == Top250Type.movies
        ? await _videoRepository.getTop250Movies()
        : await _videoRepository.getTop250Series();
    if (isClosed) return;

    if (result is DataSuccess<List<Post>>) {
      emit(Top250Success(items: List.unmodifiable(result.data ?? const [])));
      return;
    }

    if (result is DataError) {
      emit(Top250Error(message: result.errorMessage));
    }
  }
}
