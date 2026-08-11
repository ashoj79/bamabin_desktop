part of 'recently_viewed_bloc.dart';

@immutable
sealed class RecentlyViewedEvent {}

final class RecentlyViewedLoadEvent extends RecentlyViewedEvent {}

final class RecentlyViewedLoadMoreEvent extends RecentlyViewedEvent {}

final class RecentlyViewedDeleteEvent extends RecentlyViewedEvent {
  RecentlyViewedDeleteEvent(this.postId);

  final int postId;
}

final class RecentlyViewedClearAllEvent extends RecentlyViewedEvent {}

final class RecentlyViewedClearFeedbackEvent extends RecentlyViewedEvent {}
