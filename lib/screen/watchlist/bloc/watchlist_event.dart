part of 'watchlist_bloc.dart';

@immutable
sealed class WatchlistEvent {}

final class WatchlistLoadEvent extends WatchlistEvent {}

final class WatchlistLoadMoreEvent extends WatchlistEvent {}

final class WatchlistDeleteEvent extends WatchlistEvent {
  WatchlistDeleteEvent(this.postId);

  final int postId;
}

final class WatchlistClearAllEvent extends WatchlistEvent {}

final class WatchlistClearFeedbackEvent extends WatchlistEvent {}
