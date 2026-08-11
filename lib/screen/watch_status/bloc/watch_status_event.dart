part of 'watch_status_bloc.dart';

enum WatchStatusFilter {
  notWatched,
  watching,
  watched;

  String get apiValue => switch (this) {
        WatchStatusFilter.notWatched => 'not_watched',
        WatchStatusFilter.watching => 'watching',
        WatchStatusFilter.watched => 'watched',
      };

  String get label => switch (this) {
        WatchStatusFilter.notWatched => 'می‌خوام ببینم',
        WatchStatusFilter.watching => 'دارم میبینم',
        WatchStatusFilter.watched => 'دیدمش رفت',
      };

  String get emptyMessage => 'نتیجه ای برای قفسه فیلم های شما پیدا نشد.';
}

@immutable
sealed class WatchStatusEvent {}

final class WatchStatusLoadEvent extends WatchStatusEvent {
  WatchStatusLoadEvent({this.filter});

  final WatchStatusFilter? filter;
}

final class WatchStatusSelectFilterEvent extends WatchStatusEvent {
  WatchStatusSelectFilterEvent(this.filter);

  final WatchStatusFilter filter;
}

final class WatchStatusLoadMoreEvent extends WatchStatusEvent {}

final class WatchStatusDeleteEvent extends WatchStatusEvent {
  WatchStatusDeleteEvent(this.postId);

  final int postId;
}

final class WatchStatusClearFeedbackEvent extends WatchStatusEvent {}
