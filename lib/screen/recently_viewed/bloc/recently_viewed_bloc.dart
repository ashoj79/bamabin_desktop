import 'package:bamabin_desktop/data/remote/model/user/play_status.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'recently_viewed_event.dart';
part 'recently_viewed_state.dart';

class RecentlyViewedBloc
    extends Bloc<RecentlyViewedEvent, RecentlyViewedState> {
  RecentlyViewedBloc(this._videoRepository) : super(RecentlyViewedInitial()) {
    on<RecentlyViewedLoadEvent>(_onLoad);
    on<RecentlyViewedLoadMoreEvent>(_onLoadMore);
    on<RecentlyViewedDeleteEvent>(_onDelete);
    on<RecentlyViewedClearAllEvent>(_onClearAll);
    on<RecentlyViewedClearFeedbackEvent>(_onClearFeedback);
  }

  static const _pageSize = 20;

  final VideoRepository _videoRepository;

  int _page = 0;
  var _items = <PlayStatus>[];
  var _isEnd = false;
  var _isFetching = false;

  Future<void> _onLoad(
    RecentlyViewedLoadEvent event,
    Emitter<RecentlyViewedState> emit,
  ) async {
    _page = 0;
    _items = [];
    _isEnd = false;
    emit(RecentlyViewedLoading());
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onLoadMore(
    RecentlyViewedLoadMoreEvent event,
    Emitter<RecentlyViewedState> emit,
  ) async {
    if (_isEnd || _isFetching) return;
    if (state is RecentlyViewedLoading || state is RecentlyViewedLoadingMore) {
      return;
    }

    emit(RecentlyViewedLoadingMore(items: List.unmodifiable(_items)));
    await _fetch(emit: emit, reset: false);
  }

  Future<void> _fetch({
    required Emitter<RecentlyViewedState> emit,
    required bool reset,
  }) async {
    _isFetching = true;
    final result = await _videoRepository.getRecentlyViewed(_page + 1);
    if (isClosed) return;
    _isFetching = false;

    if (result is DataSuccess<List<PlayStatus>>) {
      final pageItems = result.data ?? const <PlayStatus>[];
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
        RecentlyViewedSuccess(
          items: List.unmodifiable(_items),
          hasMore: !_isEnd,
        ),
      );
      return;
    }

    if (result is DataError) {
      if (reset) {
        emit(RecentlyViewedError(message: result.errorMessage));
      } else {
        emit(
          RecentlyViewedSuccess(
            items: List.unmodifiable(_items),
            hasMore: !_isEnd,
          ),
        );
      }
    }
  }

  Future<void> _onDelete(
    RecentlyViewedDeleteEvent event,
    Emitter<RecentlyViewedState> emit,
  ) async {
    final current = state;
    if (current is! RecentlyViewedSuccess) return;
    if (current.isBusy) return;

    emit(
      current.copyWith(
        deletingPostId: event.postId,
        clearFeedback: true,
      ),
    );

    final result = await _videoRepository.deleteRecentlyViewed(event.postId);
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

    _items = _items.where((p) => p.post.id != event.postId).toList();
    emit(
      RecentlyViewedSuccess(
        items: List.unmodifiable(_items),
        hasMore: !_isEnd,
      ),
    );
  }

  Future<void> _onClearAll(
    RecentlyViewedClearAllEvent event,
    Emitter<RecentlyViewedState> emit,
  ) async {
    final current = state;
    if (current is! RecentlyViewedSuccess) return;
    if (current.isBusy || current.items.isEmpty) return;

    emit(
      current.copyWith(
        isClearingAll: true,
        clearFeedback: true,
      ),
    );

    final result = await _videoRepository.deleteRecentlyViewed(0);
    if (isClosed) return;

    if (result is DataError) {
      emit(
        current.copyWith(
          isClearingAll: false,
          feedbackMessage: result.errorMessage,
          feedbackIsError: true,
        ),
      );
      return;
    }

    _page = 0;
    _items = [];
    _isEnd = true;
    emit(
      RecentlyViewedSuccess(
        items: const [],
        hasMore: false,
        feedbackMessage: 'همه مشاهده‌های اخیر حذف شدند',
      ),
    );
  }

  void _onClearFeedback(
    RecentlyViewedClearFeedbackEvent event,
    Emitter<RecentlyViewedState> emit,
  ) {
    final current = state;
    if (current is! RecentlyViewedSuccess) return;
    emit(current.copyWith(clearFeedback: true));
  }
}
