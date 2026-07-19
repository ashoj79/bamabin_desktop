import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._videoRepository) : super(SearchInitial()) {
    on<SearchResetEvent>(_onReset);
    on<SearchQueryEvent>(_onQuery);
    on<SearchLoadMoreEvent>(_onLoadMore);
  }

  final VideoRepository _videoRepository;

  int _page = 0;
  var _posts = <Post>[];
  var _isEnd = false;
  var _lastQuery = '';
  CancelToken? _cancelToken;

  Future<void> _onReset(
    SearchResetEvent event,
    Emitter<SearchState> emit,
  ) async {
    _page = 0;
    _posts = [];
    _isEnd = false;
    _lastQuery = '';
    _cancelToken?.cancel();
    _cancelToken = null;
    emit(SearchInitial());
  }

  Future<void> _onQuery(
    SearchQueryEvent event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.length < 2) {
      await _onReset(SearchResetEvent(), emit);
      return;
    }

    _page = 0;
    _posts = [];
    _isEnd = false;
    _lastQuery = query;
    emit(SearchLoading());
    await _fetch(emit: emit, query: query, reset: true);
  }

  Future<void> _onLoadMore(
    SearchLoadMoreEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (_isEnd || _lastQuery.length < 2) return;
    if (state is SearchLoading || state is SearchLoadingMore) return;

    emit(SearchLoadingMore(posts: List.unmodifiable(_posts)));
    await _fetch(emit: emit, query: _lastQuery, reset: false);
  }

  Future<void> _fetch({
    required Emitter<SearchState> emit,
    required String query,
    required bool reset,
  }) async {
    _cancelToken?.cancel();
    final token = CancelToken();
    _cancelToken = token;

    final response = await _videoRepository.search(
      query,
      page: _page + 1,
      cancelToken: token,
    );

    if (isClosed || token.isCancelled) return;

    if (response is DataSuccess<List<Post>>) {
      final pagePosts = response.data ?? [];
      if (reset) {
        _posts = [...pagePosts];
      } else {
        _posts = [..._posts, ...pagePosts];
      }
      _page++;
      if (pagePosts.length < 10) {
        _isEnd = true;
      }
      emit(SearchSuccess(posts: List.unmodifiable(_posts), hasMore: !_isEnd));
      return;
    }

    if (response is DataError) {
      emit(SearchError(message: response.errorMessage));
    }
  }
}
