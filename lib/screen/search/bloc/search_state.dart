part of 'search_bloc.dart';

@immutable
sealed class SearchState {}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchLoadingMore extends SearchState {
  SearchLoadingMore({required this.posts});

  final List<Post> posts;
}

final class SearchSuccess extends SearchState {
  SearchSuccess({required this.posts, required this.hasMore});

  final List<Post> posts;
  final bool hasMore;
}

final class SearchError extends SearchState {
  SearchError({required this.message});

  final String message;
}
