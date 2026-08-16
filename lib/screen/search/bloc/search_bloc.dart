import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchFilters {
  const SearchFilters({
    this.type = '',
    this.genreId = 0,
    this.imdb = 0,
    this.orderBy = 'date',
    this.country = 0,
    this.language = 0,
    this.ageRate = '',
    this.network = 0,
    this.actor = '',
    this.director = '',
    this.isDubbed = false,
    this.yearFrom = 0,
    this.yearTo = 0,
  });

  final String type;
  final int genreId;
  final int imdb;
  final String orderBy;
  final int country;
  final int language;
  final String ageRate;
  final int network;
  final String actor;
  final String director;
  final bool isDubbed;
  final int yearFrom;
  final int yearTo;

  SearchFilters copyWith({
    String? type,
    int? genreId,
    int? imdb,
    String? orderBy,
    int? country,
    int? language,
    String? ageRate,
    int? network,
    String? actor,
    String? director,
    bool? isDubbed,
    int? yearFrom,
    int? yearTo,
  }) {
    return SearchFilters(
      type: type ?? this.type,
      genreId: genreId ?? this.genreId,
      imdb: imdb ?? this.imdb,
      orderBy: orderBy ?? this.orderBy,
      country: country ?? this.country,
      language: language ?? this.language,
      ageRate: ageRate ?? this.ageRate,
      network: network ?? this.network,
      actor: actor ?? this.actor,
      director: director ?? this.director,
      isDubbed: isDubbed ?? this.isDubbed,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
    );
  }

  bool get hasActiveFilters =>
      type.isNotEmpty ||
      genreId != 0 ||
      imdb != 0 ||
      (orderBy.isNotEmpty && orderBy != 'date') ||
      country != 0 ||
      language != 0 ||
      ageRate.isNotEmpty ||
      network != 0 ||
      actor.trim().isNotEmpty ||
      director.trim().isNotEmpty ||
      isDubbed ||
      yearFrom != 0 ||
      yearTo != 0;
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._videoRepository) : super(SearchInitial()) {
    on<SearchResetEvent>(_onReset);
    on<SearchQueryEvent>(_onQuery);
    on<SearchFiltersSubmitEvent>(_onFiltersSubmit);
    on<SearchOrderChangedEvent>(_onOrderChanged);
    on<SearchLoadMoreEvent>(_onLoadMore);
  }

  static const _pageSize = 10;

  final VideoRepository _videoRepository;

  int _page = 0;
  var _posts = <Post>[];
  var _isEnd = false;
  var _lastQuery = '';
  var _filters = const SearchFilters();
  var _allowShortQuery = false;
  var _isFetching = false;
  CancelToken? _cancelToken;

  SearchFilters get filters => _filters;

  bool get _canSearch =>
      _lastQuery.length >= 2 || (_allowShortQuery && _filters.hasActiveFilters);

  Future<void> _onReset(
    SearchResetEvent event,
    Emitter<SearchState> emit,
  ) async {
    _page = 0;
    _posts = [];
    _isEnd = false;
    _lastQuery = '';
    _allowShortQuery = false;
    _isFetching = false;
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
      _allowShortQuery = false;
      await _onReset(SearchResetEvent(), emit);
      return;
    }

    _allowShortQuery = false;
    _page = 0;
    _posts = [];
    _isEnd = false;
    _lastQuery = query;
    emit(SearchLoading());
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onFiltersSubmit(
    SearchFiltersSubmitEvent event,
    Emitter<SearchState> emit,
  ) async {
    _filters = event.filters;
    _lastQuery = event.query.trim();
    _allowShortQuery = true;
    _page = 0;
    _posts = [];
    _isEnd = false;
    emit(SearchLoading());
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onOrderChanged(
    SearchOrderChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    _filters = _filters.copyWith(orderBy: event.orderBy);
    if (!_canSearch) return;

    _page = 0;
    _posts = [];
    _isEnd = false;
    emit(SearchLoading());
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onLoadMore(
    SearchLoadMoreEvent event,
    Emitter<SearchState> emit,
  ) async {
    if (_isEnd || !_canSearch || _isFetching) return;
    if (state is SearchLoading) return;

    emit(SearchLoadingMore(posts: List.unmodifiable(_posts)));
    await _fetch(emit: emit, reset: false);
  }

  Future<void> _fetch({
    required Emitter<SearchState> emit,
    required bool reset,
  }) async {
    if (reset) {
      _cancelToken?.cancel();
    }
    final token = CancelToken();
    _cancelToken = token;
    _isFetching = true;

    try {
      final response = await _videoRepository.search(
        _lastQuery,
        page: _page + 1,
        type: _filters.type,
        genreId: _filters.genreId,
        imdb: _filters.imdb,
        orderBy: _filters.orderBy,
        country: _filters.country,
        language: _filters.language,
        ageRate: _filters.ageRate,
        network: _filters.network,
        actor: _filters.actor,
        director: _filters.director,
        isDubbed: _filters.isDubbed,
        yearFrom: _filters.yearFrom,
        yearTo: _filters.yearTo,
        cancelToken: token,
      );

      if (isClosed || token.isCancelled) return;

      if (response is DataSuccess<List<Post>>) {
        final pagePosts = response.data ?? const <Post>[];
        if (reset) {
          _posts = [...pagePosts];
        } else {
          _posts = [..._posts, ...pagePosts];
        }
        _page++;
        if (pagePosts.isEmpty || pagePosts.length < _pageSize) {
          _isEnd = true;
        }
        emit(
          SearchSuccess(
            posts: List.unmodifiable(_posts),
            hasMore: !_isEnd,
          ),
        );
        return;
      }

      if (response is DataError) {
        if (reset || _posts.isEmpty) {
          emit(SearchError(message: response.errorMessage));
        } else {
          emit(
            SearchSuccess(
              posts: List.unmodifiable(_posts),
              hasMore: !_isEnd,
            ),
          );
        }
      }
    } finally {
      if (identical(_cancelToken, token)) {
        _isFetching = false;
      }
    }
  }
}
