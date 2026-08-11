part of 'recently_viewed_bloc.dart';

@immutable
sealed class RecentlyViewedState {}

final class RecentlyViewedInitial extends RecentlyViewedState {}

final class RecentlyViewedLoading extends RecentlyViewedState {}

final class RecentlyViewedLoadingMore extends RecentlyViewedState {
  RecentlyViewedLoadingMore({required this.items});

  final List<PlayStatus> items;
}

final class RecentlyViewedSuccess extends RecentlyViewedState {
  RecentlyViewedSuccess({
    required this.items,
    required this.hasMore,
    this.deletingPostId,
    this.isClearingAll = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
  });

  final List<PlayStatus> items;
  final bool hasMore;
  final int? deletingPostId;
  final bool isClearingAll;
  final String? feedbackMessage;
  final bool feedbackIsError;

  bool get isBusy => deletingPostId != null || isClearingAll;

  RecentlyViewedSuccess copyWith({
    List<PlayStatus>? items,
    bool? hasMore,
    int? deletingPostId,
    bool clearDeletingPostId = false,
    bool? isClearingAll,
    String? feedbackMessage,
    bool? feedbackIsError,
    bool clearFeedback = false,
  }) {
    return RecentlyViewedSuccess(
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

final class RecentlyViewedError extends RecentlyViewedState {
  RecentlyViewedError({required this.message});

  final String message;
}
