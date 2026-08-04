part of 'post_details_bloc.dart';

@immutable
sealed class PostDetailsState {}

final class PostDetailsInitial extends PostDetailsState {}

final class PostDetailsViewState extends PostDetailsState {
  PostDetailsViewState({
    required this.preview,
    this.details,
    this.isDetailsLoading = false,
    this.detailsError,
    this.comments = const [],
    this.isCommentsLoading = false,
    this.isSubmittingComment = false,
    this.commentError,
    this.likeActionLoading,
    this.likeError,
    this.isWatchlistLoading = false,
    this.watchlistError,
  });

  final Post preview;
  final PostDetails? details;
  final bool isDetailsLoading;
  final String? detailsError;
  final List<Comment> comments;
  final bool isCommentsLoading;
  final bool isSubmittingComment;
  final String? commentError;

  /// `like` or `dislike` while request is in flight.
  final String? likeActionLoading;
  final String? likeError;
  final bool isWatchlistLoading;
  final String? watchlistError;

  PostDetailsViewState copyWith({
    Post? preview,
    PostDetails? details,
    bool? isDetailsLoading,
    String? detailsError,
    bool clearDetailsError = false,
    List<Comment>? comments,
    bool? isCommentsLoading,
    bool? isSubmittingComment,
    String? commentError,
    bool clearCommentError = false,
    String? likeActionLoading,
    bool clearLikeActionLoading = false,
    String? likeError,
    bool clearLikeError = false,
    bool? isWatchlistLoading,
    String? watchlistError,
    bool clearWatchlistError = false,
  }) {
    return PostDetailsViewState(
      preview: preview ?? this.preview,
      details: details ?? this.details,
      isDetailsLoading: isDetailsLoading ?? this.isDetailsLoading,
      detailsError: clearDetailsError
          ? null
          : (detailsError ?? this.detailsError),
      comments: comments ?? this.comments,
      isCommentsLoading: isCommentsLoading ?? this.isCommentsLoading,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      commentError: clearCommentError
          ? null
          : (commentError ?? this.commentError),
      likeActionLoading: clearLikeActionLoading
          ? null
          : (likeActionLoading ?? this.likeActionLoading),
      likeError: clearLikeError ? null : (likeError ?? this.likeError),
      isWatchlistLoading: isWatchlistLoading ?? this.isWatchlistLoading,
      watchlistError: clearWatchlistError
          ? null
          : (watchlistError ?? this.watchlistError),
    );
  }
}
