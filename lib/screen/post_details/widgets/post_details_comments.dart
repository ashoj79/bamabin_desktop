import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/comment/comment.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PostDetailsCommentsSection extends StatelessWidget {
  const PostDetailsCommentsSection({
    super.key,
    required this.comments,
    required this.isLoading,
    required this.isSubmitting,
    required this.controller,
    required this.onSubmit,
  });

  final List<Comment> comments;
  final bool isLoading;
  final bool isSubmitting;
  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    final topLevel = comments.where((c) => c.parentId == 0).toList();
    final repliesByParent = <int, List<Comment>>{};
    for (final comment in comments.where((c) => c.parentId != 0)) {
      repliesByParent.putIfAbsent(comment.parentId, () => []).add(comment);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'نظرات کاربران',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 24 / 20,
          ),
        ),
        const SizedBox(height: 16),
        _CommentComposer(
          controller: controller,
          isSubmitting: isSubmitting,
          onSubmit: onSubmit,
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Column(
            children: [
              _CommentShimmerCard(),
              SizedBox(height: 16),
              _CommentShimmerCard(),
              SizedBox(height: 16),
              _CommentShimmerCard(),
            ],
          )
        else if (topLevel.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'هنوز نظری ثبت نشده است',
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
            ),
          )
        else
          ...topLevel.map(
            (comment) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CommentCard(
                comment: comment,
                replies: repliesByParent[comment.id] ?? const [],
              ),
            ),
          ),
      ],
    );
  }
}

class _CommentComposer extends StatefulWidget {
  const _CommentComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final ValueChanged<String> onSubmit;

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  void _submit() {
    if (widget.isSubmitting) return;
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    widget.controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final initial = TempDb.username.isNotEmpty ? TempDb.username[0] : 'ک';
    final avatarUrl = TempDb.avatar;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _ComposerAvatar(initial: initial, avatarUrl: avatarUrl),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: widget.controller,
            maxLines: 1,
            onSubmitted: (_) => _submit(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            decoration: InputDecoration(
              hintText: 'نظر خود را بنویسید',
              hintStyle: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.48),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: desktopMutedColor, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Material(
            color: blueColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: widget.isSubmitting ? null : _submit,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                child: widget.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ارسال دیدگاه',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ComposerAvatar extends StatelessWidget {
  const _ComposerAvatar({required this.initial, required this.avatarUrl});

  final String initial;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [desktopAccentDarkColor, blueColor],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: avatarUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: avatarUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => _initialText(),
              placeholder: (context, url) => _initialText(),
            )
          : _initialText(),
    );
  }

  Widget _initialText() => Text(
        initial,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.replies,
  });

  final Comment comment;
  final List<Comment> replies;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x7A131321),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CommentHeader(
            author: comment.author,
            date: comment.date,
          ),
          const SizedBox(height: 16),
          _CommentBody(
            content: comment.content,
            hasSpoil: comment.hasSpoil,
          ),
          const SizedBox(height: 16),
          _CommentActions(
            likes: comment.likeInfo.likes,
            dislikes: comment.likeInfo.dislikes,
            replyCount: replies.length,
          ),
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...replies.map(
              (reply) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CommentReply(reply: reply),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentHeader extends StatelessWidget {
  const _CommentHeader({required this.author, required this.date});

  final String author;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          author,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 24 / 20,
          ),
        ),
        const Spacer(),
        if (date.isNotEmpty)
          Text(
            date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
              height: 22 / 16,
            ),
          ),
      ],
    );
  }
}

class _CommentBody extends StatefulWidget {
  const _CommentBody({required this.content, required this.hasSpoil});

  final String content;
  final bool hasSpoil;

  @override
  State<_CommentBody> createState() => _CommentBodyState();
}

class _CommentBodyState extends State<_CommentBody> {
  var _spoilerRevealed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.hasSpoil && !_spoilerRevealed) {
      return Material(
          color: Colors.transparent,
          child: InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: () => setState(() => _spoilerRevealed = true),
            borderRadius: BorderRadius.circular(24),
            child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: blueColor.withValues(alpha: 0.5),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/img/baseline_visibility_off_24.svg',
                  width: 54,
                  height: 54,
                  colorFilter: ColorFilter.mode(blueColor, BlendMode.srcIn),
                ),
                const SizedBox(height: 6),
                Text(
                  'این نظر شامل اسپویلر است',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: blueColor,
                    height: 22 / 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'برای مشاهده ضربه بزنید',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        );
    }

    return Text(
      widget.content,
      textAlign: TextAlign.justify,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: Color(0xFFF5EFE6),
        height: 24 / 20,
      ),
    );
  }
}

class _CommentActions extends StatelessWidget {
  const _CommentActions({
    required this.likes,
    required this.dislikes,
    required this.replyCount,
  });

  final int likes;
  final int dislikes;
  final int replyCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _VoteActionButton(
          icon: Icons.thumb_up_alt_outlined,
          count: likes,
          highlighted: likes > dislikes,
        ),
        const SizedBox(width: 6),
        _VoteActionButton(
          icon: Icons.thumb_down_alt_outlined,
          count: dislikes,
          highlighted: false,
        ),
        const Spacer(),
        Text(
          '$replyCount پاسخ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: blueColor,
          ),
        ),
      ],
    );
  }
}

class _VoteActionButton extends StatelessWidget {
  const _VoteActionButton({
    required this.icon,
    required this.count,
    required this.highlighted,
  });

  final IconData icon;
  final int count;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? blueColor.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              color: highlighted
                  ? blueColor
                  : Colors.white.withValues(alpha: 0.48),
            ),
          ),
          const SizedBox(width: 5),
          Icon(
            icon,
            size: 18,
            color: highlighted ? blueColor : Colors.white.withValues(alpha: 0.48),
          ),
        ],
      ),
    );
  }
}

class _CommentReply extends StatelessWidget {
  const _CommentReply({required this.reply});

  final Comment reply;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: blueColor, width: 4),
        ),
      ),
      padding: const EdgeInsets.only(right: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CommentHeader(
              author: reply.author,
              date: reply.date,
            ),
            const SizedBox(height: 16),
            Text(
              reply.content,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
                height: 24 / 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentShimmerCard extends StatelessWidget {
  const _CommentShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0x7A131321),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 80, height: 20, radius: 4),
              Spacer(),
              _ShimmerBox(width: 100, height: 16, radius: 4),
            ],
          ),
          SizedBox(height: 16),
          _ShimmerBox(width: double.infinity, height: 16, radius: 4),
          SizedBox(height: 8),
          _ShimmerBox(width: 280, height: 16, radius: 4),
          SizedBox(height: 16),
          Row(
            children: [
              _ShimmerBox(width: 64, height: 32, radius: 9),
              SizedBox(width: 6),
              _ShimmerBox(width: 64, height: 32, radius: 9),
              Spacer(),
              _ShimmerBox(width: 56, height: 16, radius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      color: Colors.white,
      colorOpacity: 0.08,
      child: Container(
        width: width == double.infinity ? null : width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A22),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
