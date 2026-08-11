part of 'watchlist_bloc.dart';

@immutable
sealed class WatchlistState {}

final class WatchlistInitial extends WatchlistState {}

final class WatchlistLoading extends WatchlistState {}

final class WatchlistLoadingMore extends WatchlistState {
  WatchlistLoadingMore({required this.items});

  final List<Post> items;
}

final class WatchlistSuccess extends WatchlistState {
  WatchlistSuccess({
    required this.items,
    required this.hasMore,
    this.deletingPostId,
    this.isClearingAll = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final List<Post> items;
  final bool hasMore;
  final int? deletingPostId;
  final bool isClearingAll;
  final String? feedbackMessage;
  final bool feedbackIsError;

  bool get isBusy => deletingPostId != null || isClearingAll;

  WatchlistSuccess copyWith({
    List<Post>? items,
    bool? hasMore,
    int? deletingPostId,
    bool clearDeletingPostId = false,
    bool? isClearingAll,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return WatchlistSuccess(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      deletingPostId: clearDeletingPostId
          ? null
          : (deletingPostId ?? this.deletingPostId),
      isClearingAll: isClearingAll ?? this.isClearingAll,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
    );
  }
}

final class WatchlistError extends WatchlistState {
  WatchlistError({required this.message});

  final String message;
}
