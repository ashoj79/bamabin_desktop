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
      view = view.copyWith(
        comments: commentsResponse.data ?? const [],
        isCommentsLoading: false,
      );
    } else {
      view = view.copyWith(
        comments: const [],
        isCommentsLoading: false,
      );
    }
    emit(view);
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
      emit(
        refreshed.copyWith(
          isSubmittingComment: false,
          comments: commentsResponse is DataSuccess<List<Comment>>
              ? (commentsResponse.data ?? refreshed.comments)
              : refreshed.comments,
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

