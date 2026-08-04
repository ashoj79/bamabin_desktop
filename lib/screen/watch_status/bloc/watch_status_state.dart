part of 'watch_status_bloc.dart';

@immutable
sealed class WatchStatusState {}

final class WatchStatusInitial extends WatchStatusState {}

final class WatchStatusLoading extends WatchStatusState {}

final class WatchStatusLoadingMore extends WatchStatusState {
  WatchStatusLoadingMore({required this.items});

  final List<PlayStatus> items;
}

final class WatchStatusSuccess extends WatchStatusState {
  WatchStatusSuccess({required this.items, required this.hasMore});

  final List<PlayStatus> items;
  final bool hasMore;
}

final class WatchStatusError extends WatchStatusState {
  WatchStatusError({required this.message});

  final String message;
}
