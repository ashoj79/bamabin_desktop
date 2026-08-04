import 'package:bamabin_desktop/data/remote/model/user/play_status.dart';
import 'package:bamabin_desktop/repository/user_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'watch_status_event.dart';
part 'watch_status_state.dart';

class WatchStatusBloc extends Bloc<WatchStatusEvent, WatchStatusState> {
  WatchStatusBloc(this._userRepository) : super(WatchStatusInitial()) {
    on<WatchStatusLoadEvent>(_onLoad);
    on<WatchStatusLoadMoreEvent>(_onLoadMore);
  }

  static const _pageSize = 10;

  final UserRepository _userRepository;

  int _page = 0;
  var _items = <PlayStatus>[];
  var _isEnd = false;

  Future<void> _onLoad(
    WatchStatusLoadEvent event,
    Emitter<WatchStatusState> emit,
  ) async {
    _page = 0;
    _items = [];
    _isEnd = false;
    emit(WatchStatusLoading());
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onLoadMore(
    WatchStatusLoadMoreEvent event,
    Emitter<WatchStatusState> emit,
  ) async {
    if (_isEnd) return;
    if (state is WatchStatusLoading || state is WatchStatusLoadingMore) return;

    emit(WatchStatusLoadingMore(items: List.unmodifiable(_items)));
    await _fetch(emit: emit, reset: false);
  }

  Future<void> _fetch({
    required Emitter<WatchStatusState> emit,
    required bool reset,
  }) async {
    final result = await _userRepository.getPlayStatus(page: _page + 1);
    if (isClosed) return;

    if (result is DataSuccess<List<PlayStatus>>) {
      final pageItems = result.data ?? const <PlayStatus>[];
      if (reset) {
        _items = [...pageItems];
      } else {
        _items = [..._items, ...pageItems];
      }
      _page++;
      if (pageItems.length < _pageSize) {
        _isEnd = true;
      }
      emit(
        WatchStatusSuccess(
          items: List.unmodifiable(_items),
          hasMore: !_isEnd,
        ),
      );
      return;
    }

    if (result is DataError) {
      if (reset) {
        emit(WatchStatusError(message: result.errorMessage));
      } else {
        emit(
          WatchStatusSuccess(
            items: List.unmodifiable(_items),
            hasMore: !_isEnd,
          ),
        );
      }
    }
  }
}
