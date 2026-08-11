import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/repository/user_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'watch_status_event.dart';
part 'watch_status_state.dart';

class WatchStatusBloc extends Bloc<WatchStatusEvent, WatchStatusState> {
  WatchStatusBloc(this._userRepository) : super(WatchStatusInitial()) {
    on<WatchStatusLoadEvent>(_onLoad);
    on<WatchStatusSelectFilterEvent>(_onSelectFilter);
    on<WatchStatusLoadMoreEvent>(_onLoadMore);
    on<WatchStatusDeleteEvent>(_onDelete);
    on<WatchStatusClearFeedbackEvent>(_onClearFeedback);
  }

  static const _pageSize = 20;

  final UserRepository _userRepository;

  WatchStatusFilter _filter = WatchStatusFilter.notWatched;
  int _page = 0;
  var _items = <Post>[];
  var _isEnd = false;
  var _isFetching = false;

  Future<void> _onLoad(
    WatchStatusLoadEvent event,
    Emitter<WatchStatusState> emit,
  ) async {
    if (event.filter != null) {
      _filter = event.filter!;
    }
    _page = 0;
    _items = [];
    _isEnd = false;
    emit(WatchStatusLoading(filter: _filter));
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onSelectFilter(
    WatchStatusSelectFilterEvent event,
    Emitter<WatchStatusState> emit,
  ) async {
    if (_filter == event.filter && state is WatchStatusSuccess) return;
    _filter = event.filter;
    _page = 0;
    _items = [];
    _isEnd = false;
    emit(WatchStatusLoading(filter: _filter));
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onLoadMore(
    WatchStatusLoadMoreEvent event,
    Emitter<WatchStatusState> emit,
  ) async {
    if (_isEnd || _isFetching) return;
    if (state is WatchStatusLoading || state is WatchStatusLoadingMore) return;

    emit(
      WatchStatusLoadingMore(
        items: List.unmodifiable(_items),
        filter: _filter,
      ),
    );
    await _fetch(emit: emit, reset: false);
  }

  Future<void> _fetch({
    required Emitter<WatchStatusState> emit,
    required bool reset,
  }) async {
    _isFetching = true;
    final result = await _userRepository.getWatchStatusPosts(
      _filter.apiValue,
      _page + 1,
    );
    if (isClosed) return;
    _isFetching = false;

    if (result is DataSuccess<List<Post>>) {
      final pageItems = result.data ?? const <Post>[];
      if (reset) {
        _items = [...pageItems];
      } else {
        _items = [..._items, ...pageItems];
      }
      _page++;
      if (pageItems.isEmpty || pageItems.length < _pageSize) {
        _isEnd = true;
      }
      emit(
        WatchStatusSuccess(
          items: List.unmodifiable(_items),
          filter: _filter,
          hasMore: !_isEnd,
        ),
      );
      return;
    }

    if (result is DataError) {
      if (reset) {
        emit(
          WatchStatusError(
            message: result.errorMessage,
            filter: _filter,
          ),
        );
      } else {
        emit(
          WatchStatusSuccess(
            items: List.unmodifiable(_items),
            filter: _filter,
            hasMore: !_isEnd,
          ),
        );
      }
    }
  }

  Future<void> _onDelete(
    WatchStatusDeleteEvent event,
    Emitter<WatchStatusState> emit,
  ) async {
    final current = state;
    if (current is! WatchStatusSuccess) return;
    if (current.deletingPostId != null) return;

    emit(
      current.copyWith(
        deletingPostId: event.postId,
        clearFeedback: true,
      ),
    );

    final result = await _userRepository.deleteWatchStatusPost(
      _filter.apiValue,
      event.postId,
    );
    if (isClosed) return;

    if (result is DataError) {
      emit(
        current.copyWith(
          clearDeletingPostId: true,
          feedbackMessage: result.errorMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    _items = _items.where((p) => p.id != event.postId).toList();
    emit(
      WatchStatusSuccess(
        items: List.unmodifiable(_items),
        filter: _filter,
        hasMore: !_isEnd,
      ),
    );
  }

  void _onClearFeedback(
    WatchStatusClearFeedbackEvent event,
    Emitter<WatchStatusState> emit,
  ) {
    final current = state;
    if (current is! WatchStatusSuccess) return;
    emit(current.copyWith(clearFeedback: true));
  }
}
