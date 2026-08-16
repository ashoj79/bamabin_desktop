import 'package:bamabin_desktop/data/local/post_type.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/screen/categories/taxonomy_posts_args.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'taxonomy_posts_event.dart';
part 'taxonomy_posts_state.dart';

class TaxonomyPostsBloc extends Bloc<TaxonomyPostsEvent, TaxonomyPostsState> {
  TaxonomyPostsBloc(this._videoRepository, this.args)
      : super(const TaxonomyPostsInitial()) {
    on<TaxonomyPostsLoadEvent>(_onLoad);
    on<TaxonomyPostsLoadMoreEvent>(_onLoadMore);
    on<TaxonomyPostsFiltersChangedEvent>(_onFiltersChanged);
  }

  final VideoRepository _videoRepository;
  final TaxonomyPostsArgs args;

  int _page = 0;
  var _items = <Post>[];
  var _isEnd = false;
  var _isFetching = false;
  PostType? _postType;
  int _genreId = 0;
  String _orderBy = '';
  int _imdb = 0;

  bool get lockGenre => args.taxonomy == 'genres';

  int get _effectiveGenreId => lockGenre ? 0 : _genreId;

  Future<void> _onLoad(
    TaxonomyPostsLoadEvent event,
    Emitter<TaxonomyPostsState> emit,
  ) async {
    _page = 0;
    _items = [];
    _isEnd = false;
    emit(TaxonomyPostsLoading(filters: _filtersView()));
    await _fetch(emit: emit, reset: true);
  }

  Future<void> _onLoadMore(
    TaxonomyPostsLoadMoreEvent event,
    Emitter<TaxonomyPostsState> emit,
  ) async {
    if (_isEnd || _isFetching) return;
    if (state is TaxonomyPostsLoading || state is TaxonomyPostsLoadingMore) {
      return;
    }

    emit(
      TaxonomyPostsLoadingMore(
        items: List.unmodifiable(_items),
        filters: _filtersView(),
      ),
    );
    await _fetch(emit: emit, reset: false);
  }

  Future<void> _onFiltersChanged(
    TaxonomyPostsFiltersChangedEvent event,
    Emitter<TaxonomyPostsState> emit,
  ) async {
    _postType = event.postType;
    if (!lockGenre) _genreId = event.genreId;
    _orderBy = event.orderBy;
    _imdb = event.imdb;
    await _onLoad(TaxonomyPostsLoadEvent(), emit);
  }

  Future<void> _fetch({
    required Emitter<TaxonomyPostsState> emit,
    required bool reset,
  }) async {
    _isFetching = true;
    final result = await _videoRepository.getPostWithTaxonomy(
      args.taxonomy,
      args.id,
      _effectiveGenreId,
      _postType?.value ?? '',
      _orderBy,
      _imdb,
      _page + 1,
    );
    if (isClosed) return;
    _isFetching = false;

    if (result is DataSuccess<List<Post>>) {
      final pageItems = result.data ?? const <Post>[];
      final previousCount = reset ? 0 : _items.length;
      if (reset) {
        _items = [...pageItems];
      } else {
        _items = [..._items, ...pageItems];
      }
      _page++;
      if (pageItems.isEmpty) {
        _isEnd = true;
      } else if (!reset) {
        final existingIds =
            _items.take(previousCount).map((p) => p.id).toSet();
        if (pageItems.every((p) => existingIds.contains(p.id))) {
          _isEnd = true;
        }
      }
      emit(
        TaxonomyPostsSuccess(
          items: List.unmodifiable(_items),
          hasMore: !_isEnd,
          filters: _filtersView(),
        ),
      );
      return;
    }

    if (result is DataError) {
      final message = result.errorMessage;
      if (reset) {
        emit(TaxonomyPostsError(message: message, filters: _filtersView()));
      } else {
        emit(
          TaxonomyPostsSuccess(
            items: List.unmodifiable(_items),
            hasMore: !_isEnd,
            filters: _filtersView(),
          ),
        );
      }
    }
  }

  TaxonomyPostsFiltersView _filtersView() {
    return TaxonomyPostsFiltersView(
      postType: _postType,
      genreId: lockGenre ? args.id : _genreId,
      orderBy: _orderBy,
      imdb: _imdb,
      lockGenre: lockGenre,
    );
  }
}
