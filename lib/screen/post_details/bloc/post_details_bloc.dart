import 'package:bamabin_desktop/data/remote/model/comment/comment.dart';
import 'package:bamabin_desktop/data/remote/model/videos/like_info.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'post_details_event.dart';
part 'post_details_state.dart';

class PostDetailsBloc extends Bloc<PostDetailsEvent, PostDetailsState> {
  PostDetailsBloc(this._videoRepository) : super(PostDetailsInitial()) {
    on<LoadPostDetailsEvent>(_onLoadPostDetails);
    on<LoadMoreCommentsEvent>(_onLoadMoreComments);
    on<SubmitCommentEvent>(_onSubmitComment);
    on<LikePostEvent>(_onLikePost);
    on<ToggleWatchlistEvent>(_onToggleWatchlist);
  }

  final VideoRepository _videoRepository;

  Future<void> _onLoadPostDetails(
    LoadPostDetailsEvent event,
    Emitter<PostDetailsState> emit,
  ) async {
    var view = PostDetailsViewState(
      preview: event.post,
      isDetailsLoading: true,
      isCommentsLoading: true,
      commentsPage: 0,
      hasMoreComments: false,
    );
    emit(view);

    final detailsFuture = _videoRepository.getPostDetails(event.post.id);
    final commentsFuture = _videoRepository.getComments(event.post.id, 1);

    final detailsResponse = await detailsFuture;
    if (emit.isDone) return;

    if (detailsResponse is DataSuccess<PostDetails>) {
      view = view.copyWith(
        details: detailsResponse.data,
        isDetailsLoading: false,
        clearDetailsError: true,
      );
    } else {
      view = view.copyWith(
        isDetailsLoading: false,
        detailsError: detailsResponse.errorMessage,
      );
    }
    emit(view);

    final commentsResponse = await commentsFuture;
    if (emit.isDone) return;

    if (commentsResponse is DataSuccess<List<Comment>>) {
      final pageItems = commentsResponse.data ?? const <Comment>[];
      view = view.copyWith(
        comments: pageItems,
        commentsPage: 1,
        // Keep offering "more" until an empty page is received.
        hasMoreComments: pageItems.isNotEmpty,
        isCommentsLoading: false,
      );
    } else {
      view = view.copyWith(
        comments: const [],
        commentsPage: 0,
        hasMoreComments: false,
        isCommentsLoading: false,
      );
    }
    emit(view);
  }

  Future<void> _onLoadMoreComments(
    LoadMoreCommentsEvent event,
    Emitter<PostDetailsState> emit,
  ) async {
    final current = state;
    if (current is! PostDetailsViewState) return;
    if (current.isCommentsLoading ||
        current.isLoadingMoreComments ||
        !current.hasMoreComments) {
      return;
    }

    final nextPage = current.commentsPage + 1;
    emit(current.copyWith(isLoadingMoreComments: true));

    final response = await _videoRepository.getComments(
      event.postId,
      nextPage,
    );

    final latest = state;
    if (latest is! PostDetailsViewState) return;

    if (response is DataSuccess<List<Comment>>) {
      final pageItems = response.data ?? const <Comment>[];
      if (pageItems.isEmpty) {
        emit(
          latest.copyWith(
            hasMoreComments: false,
            isLoadingMoreComments: false,
          ),
        );
        return;
      }

      final existingIds = latest.comments.map((c) => c.id).toSet();
      final appended = [
        ...latest.comments,
        ...pageItems.where((c) => !existingIds.contains(c.id)),
      ];
      emit(
        latest.copyWith(
          comments: appended,
          commentsPage: nextPage,
          hasMoreComments: true,
          isLoadingMoreComments: false,
        ),
      );
    } else {
      emit(
        latest.copyWith(
          isLoadingMoreComments: false,
          hasMoreComments: false,
        ),
      );
    }
  }

  Future<void> _onSubmitComment(
    SubmitCommentEvent event,
    Emitter<PostDetailsState> emit,
  ) async {
    final current = state;
    if (current is! PostDetailsViewState) return;

    emit(current.copyWith(isSubmittingComment: true));

    final response = await _videoRepository.addComment(
      event.postId,
      event.content,
      event.hasSpoil,
      0,
    );

    final latest = state;
    if (latest is! PostDetailsViewState) return;

    if (response is DataSuccess) {
      final commentsResponse = await _videoRepository.getComments(
        event.postId,
        1,
      );
      final refreshed = state;
      if (refreshed is! PostDetailsViewState) return;
      final pageItems = commentsResponse is DataSuccess<List<Comment>>
          ? (commentsResponse.data ?? refreshed.comments)
          : refreshed.comments;
      emit(
        refreshed.copyWith(
          isSubmittingComment: false,
          comments: pageItems,
          commentsPage: 1,
          hasMoreComments: pageItems.isNotEmpty,
        ),
      );
    } else {
      emit(
        latest.copyWith(
          isSubmittingComment: false,
          commentError: response.errorMessage,
        ),
      );
    }
  }

  Future<void> _onLikePost(
    LikePostEvent event,
    Emitter<PostDetailsState> emit,
  ) async {
    final current = state;
    if (current is! PostDetailsViewState) return;
    if (current.likeActionLoading != null) return;
    if (current.details == null) return;

    emit(
      current.copyWith(
        likeActionLoading: event.action,
        clearLikeError: true,
      ),
    );

    final response = await _videoRepository.likePost(
      event.postId,
      event.action,
    );

    final latest = state;
    if (latest is! PostDetailsViewState) return;

    if (response is DataSuccess<LikeInfo>) {
      final details = latest.details!;
      details.likeInfo = response.data;
      details.userRate = event.action;
      emit(
        latest.copyWith(
          details: details,
          clearLikeActionLoading: true,
        ),
      );
    } else {
      emit(
        latest.copyWith(
          clearLikeActionLoading: true,
          likeError: response.errorMessage,
        ),
      );
    }
  }

  Future<void> _onToggleWatchlist(
    ToggleWatchlistEvent event,
    Emitter<PostDetailsState> emit,
  ) async {
    final current = state;
    if (current is! PostDetailsViewState) return;
    if (current.isWatchlistLoading) return;
    if (current.details == null) return;

    final currentlyInList = current.details!.isInWatchlist;
    final action = currentlyInList ? 'remove' : 'add';

    emit(
      current.copyWith(
        isWatchlistLoading: true,
        clearWatchlistError: true,
      ),
    );

    final response = await _videoRepository.updateWatchList(
      event.postId,
      action,
    );

    final latest = state;
    if (latest is! PostDetailsViewState) return;

    if (response is DataSuccess) {
      final details = latest.details!;
      details.isInWatchlist = !currentlyInList;
      emit(
        latest.copyWith(
          details: details,
          isWatchlistLoading: false,
        ),
      );
    } else {
      emit(
        latest.copyWith(
          isWatchlistLoading: false,
          watchlistError: response.errorMessage,
        ),
      );
    }
  }
}

