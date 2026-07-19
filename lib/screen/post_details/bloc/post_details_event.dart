part of 'post_details_bloc.dart';

@immutable
sealed class PostDetailsEvent {}

final class LoadPostDetailsEvent extends PostDetailsEvent {
  LoadPostDetailsEvent(this.post);

  final Post post;
}

final class SubmitCommentEvent extends PostDetailsEvent {
  SubmitCommentEvent({
    required this.postId,
    required this.content,
    this.hasSpoil = false,
  });

  final int postId;
  final String content;
  final bool hasSpoil;
}
