part of 'taxonomy_posts_bloc.dart';

@immutable
class TaxonomyPostsFiltersView {
  const TaxonomyPostsFiltersView({
    required this.postType,
    required this.genreId,
    required this.orderBy,
    required this.imdb,
    required this.lockGenre,
  });

  final PostType? postType;
  final int genreId;
  final String orderBy;
  final int imdb;
  final bool lockGenre;
}

@immutable
sealed class TaxonomyPostsState {
  const TaxonomyPostsState({required this.filters});

  final TaxonomyPostsFiltersView filters;
}

final class TaxonomyPostsInitial extends TaxonomyPostsState {
  const TaxonomyPostsInitial()
      : super(
          filters: const TaxonomyPostsFiltersView(
            postType: null,
            genreId: 0,
            orderBy: '',
            imdb: 0,
            lockGenre: false,
          ),
        );
}

final class TaxonomyPostsLoading extends TaxonomyPostsState {
  const TaxonomyPostsLoading({required super.filters});
}

final class TaxonomyPostsLoadingMore extends TaxonomyPostsState {
  const TaxonomyPostsLoadingMore({
    required this.items,
    required super.filters,
  });

  final List<Post> items;
}

final class TaxonomyPostsSuccess extends TaxonomyPostsState {
  const TaxonomyPostsSuccess({
    required this.items,
    required this.hasMore,
    required super.filters,
  });

  final List<Post> items;
  final bool hasMore;
}

final class TaxonomyPostsError extends TaxonomyPostsState {
  const TaxonomyPostsError({
    required this.message,
    required super.filters,
  });

  final String message;
}
