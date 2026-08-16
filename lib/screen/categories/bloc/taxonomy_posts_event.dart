part of 'taxonomy_posts_bloc.dart';

@immutable
sealed class TaxonomyPostsEvent {}

final class TaxonomyPostsLoadEvent extends TaxonomyPostsEvent {}

final class TaxonomyPostsLoadMoreEvent extends TaxonomyPostsEvent {}

final class TaxonomyPostsFiltersChangedEvent extends TaxonomyPostsEvent {
  TaxonomyPostsFiltersChangedEvent({
    this.postType,
    required this.genreId,
    required this.orderBy,
    required this.imdb,
  });

  final PostType? postType;
  final int genreId;
  final String orderBy;
  final int imdb;
}
