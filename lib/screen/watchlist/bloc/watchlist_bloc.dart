import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'watchlist_event.dart';
part 'watchlist_state.dart';

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc(this._videoRepository) : super(WatchlistInitial()) {
    on<WatchlistLoadEvent>(_onLoad);
    on<WatchlistLoadMoreEvent>(_onLoadMore);
    on<WatchlistDeleteEvent>(_onDelete);
    on<WatchlistClearAllEvent>(_onClearAll);
    on<WatchlistClearFeedbackEvent>(_onClearFeedback);
  }

  static const _pageSize = 20;

  final VideoRepository _videoRepository;

  int _page = 0;
  var _items = <Post>[];
  var _isEnd = false;
  var _isFetching = false;

  Future<void> _onLoad(
    WatchlistLoadEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    _page = 0;
    _items = [];
    _isEnd = false;
    emit(WatchlistLoading());
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onLoadMore(
    WatchlistLoadMoreEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    if (_isEnd || _isFetching) return;
    if (state is WatchlistLoading || state is WatchlistLoadingMore) return;

    emit(WatchlistLoadingMore(items: List.unmodifiable(_items)));
    await _fetch(emit: emit, reset: false);
  }

  Future<void> _fetch({
    required Emitter<WatchlistState> emit,
    required bool reset,
  }) async {
    _isFetching = true;
    final result = await _videoRepository.getWatchList(_page + 1);
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
        WatchlistSuccess(
          items: List.unmodifiable(_items),
          hasMore: !_isEnd,
        ),
      );
      return;
    }

    if (result is DataError) {
      if (reset) {
        emit(WatchlistError(message: result.errorMessage));
      } else {
        emit(
          WatchlistSuccess(
            items: List.unmodifiable(_items),
            hasMore: !_isEnd,
          ),
        );
      }
    }
  }

  Future<void> _onDelete(
    WatchlistDeleteEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    final current = state;
    if (current is! WatchlistSuccess) return;
    if (current.isBusy) return;

    emit(
      current.copyWith(
        deletingPostId: event.postId,
        clearFeedback: true,
      ),
    );

    final result = await _videoRepository.updateWatchList(
      event.postId,
      'remove',
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
      WatchlistSuccess(
        items: List.unmodifiable(_items),
        hasMore: !_isEnd,
      ),
    );
  }

  Future<void> _onClearAll(
    WatchlistClearAllEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    final current = state;
    if (current is! WatchlistSuccess) return;
    if (current.isBusy || current.items.isEmpty) return;

    emit(
      current.copyWith(
        isClearingAll: true,
        clearFeedback: true,
      ),
    );

    while (true) {
      final pageResult = await _videoRepository.getWatchList(1);
      if (isClosed) return;

      if (pageResult is DataError) {
        emit(
          current.copyWith(
            isClearingAll: false,
            feedbackMessage: pageResult.errorMessage,
            feedbackIsError: true,
          ),
        );
        return;
      }

      final pageItems = pageResult.data ?? const <Post>[];
      if (pageItems.isEmpty) break;

      for (final post in pageItems) {
        final removeResult = await _videoRepository.updateWatchList(
          post.id,
          'remove',
        );
        if (isClosed) return;
        if (removeResult is DataError) {
          emit(
            current.copyWith(
              isClearingAll: false,
              feedbackMessage: removeResult.errorMessage,
              feedbackIsError: true,
            ),
          );
          await _reloadAfterPartialClear(emit);
          return;
        }
      }
    }

    _page = 0;
    _items = [];
    _isEnd = true;
    emit(
      WatchlistSuccess(
        items: const [],
        hasMore: false,
        feedbackMessage: 'همه علاقه‌مندی‌ها حذف شدند',
      ),
    );
  }

  Future<void> _reloadAfterPartialClear(Emitter<WatchlistState> emit) async {
    _page = 0;
    _items = [];
    _isEnd = false;
    await _fetch(emit: emit, reset: true);
  }

  void _onClearFeedback(
    WatchlistClearFeedbackEvent event,
    Emitter<WatchlistState> emit,
  ) {
    final current = state;
    if (current is! WatchlistSuccess) return;
    emit(current.copyWith(clearFeedback: true));
  }
}
