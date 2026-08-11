part of 'watch_status_bloc.dart';

@immutable
sealed class WatchStatusState {}

final class WatchStatusInitial extends WatchStatusState {}

final class WatchStatusLoading extends WatchStatusState {
  WatchStatusLoading({this.filter = WatchStatusFilter.notWatched});

  final WatchStatusFilter filter;
}

final class WatchStatusLoadingMore extends WatchStatusState {
  WatchStatusLoadingMore({
    required this.items,
    required this.filter,
  });

  final List<Post> items;
  final WatchStatusFilter filter;
}

final class WatchStatusSuccess extends WatchStatusState {
  WatchStatusSuccess({
    required this.items,
    required this.filter,
    required this.hasMore,
    this.deletingPostId,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final List<Post> items;
  final WatchStatusFilter filter;
  final bool hasMore;
  final int? deletingPostId;
  final String? feedbackMessage;
  final bool feedbackIsError;

  WatchStatusSuccess copyWith({
    List<Post>? items,
    WatchStatusFilter? filter,
    bool? hasMore,
    int? deletingPostId,
    bool clearDeletingPostId = false,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return WatchStatusSuccess(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      hasMore: hasMore ?? this.hasMore,
      deletingPostId: clearDeletingPostId
          ? null
          : (deletingPostId ?? this.deletingPostId),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }
}

final class WatchStatusError extends WatchStatusState {
  WatchStatusError({
    required this.message,
    this.filter = WatchStatusFilter.notWatched,
  });

  final String message;
  final WatchStatusFilter filter;
}
