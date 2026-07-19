part of 'search_bloc.dart';

@immutable
sealed class SearchEvent {}

final class SearchResetEvent extends SearchEvent {}

final class SearchQueryEvent extends SearchEvent {
  SearchQueryEvent(this.query);

  final String query;
}

final class SearchLoadMoreEvent extends SearchEvent {}
