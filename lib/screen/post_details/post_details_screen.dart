import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/post_widget.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/comment/comment.dart';
import 'package:bamabin_desktop/data/remote/model/videos/like_info.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/screen/post_details/bloc/post_details_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PostDetailsScreen extends StatefulWidget {
  const PostDetailsScreen({super.key});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: desktopBgColor,
      child: BlocBuilder<PostDetailsBloc, PostDetailsState>(
        builder: (context, state) {
          if (state is! PostDetailsViewState) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF29B6F6)),
            );
          }
          return _PostDetailsBody(
            state: state,
            commentController: _commentController,
          );
        },
      ),
    );
  }
}

class _PostDetailsBody extends StatelessWidget {
  const _PostDetailsBody({
    required this.state,
    required this.commentController,
  });

  final PostDetailsViewState state;
  final TextEditingController commentController;

  Post get preview => state.preview;
  PostDetails? get details => state.details;

  String get _faTitle {
    final fromDetails = details?.faTitle ?? '';
    if (fromDetails.isNotEmpty) return fromDetails;
    return preview.faTitle.isNotEmpty ? preview.faTitle : preview.title;
  }

  String get _enTitle {
    final title = details?.title ?? preview.title;
    if (_faTitle.isNotEmpty && title.isNotEmpty && title != _faTitle) {
      return title;
    }
    return '';
  }

  String get _heroUrl {
    final bg = details?.bgThumbnail ?? '';
    if (bg.isNotEmpty) return bg;
    if (preview.bgThumbnail.isNotEmpty) return preview.bgThumbnail;
    return preview.thumbnail;
  }

  String get _posterUrl {
    if (preview.thumbnail.isNotEmpty) return preview.thumbnail;
    return _heroUrl;
  }

  List<String> get _genreNames {
    final ids = details?.genresId.isNotEmpty == true
        ? details!.genresId
        : preview.genresId;
    if (ids.isEmpty || TempDb.genres.isEmpty) return const [];
    final byId = {for (final g in TempDb.genres) g.id: g.name};
    return ids
        .map((id) => byId[id])
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .take(4)
        .toList();
  }

  String get _imdbRate {
    final rate = details?.imdbRate ?? preview.imdbRate;
    return rate;
  }

  String get _year {
    if (details != null && details!.years.isNotEmpty) {
      return details!.years.first.name;
    }
    return preview.releaseYear == '0' ? '' : preview.releaseYear;
  }

  @override
  Widget build(BuildContext context) {
    // Desktop banner — taller than the 400px HTML mock for wide screens
    const heroHeight = 520.0;
    const overlap = 100.0;

    return SingleChildScrollView(
      child: Stack(
        children: [
          SizedBox(
            height: heroHeight,
            width: double.infinity,
            child: _HeroHeader(imageUrl: _heroUrl, height: heroHeight),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, heroHeight - overlap, 36, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderRow(
                  posterUrl: _posterUrl,
                  genreNames: _genreNames,
                  faTitle: _faTitle,
                  enTitle: _enTitle,
                  imdbRate: _imdbRate,
                  voteCount: details?.imdbVoteCount,
                  year: _year,
                  duration: details?.getTime(),
                  summary: details?.summary,
                  likeInfo: details?.likeInfo,
                  isDetailsLoading: state.isDetailsLoading,
                  isInWatchlist: details?.isInWatchlist ?? false,
                ),
                const SizedBox(height: 34),
                _CastSection(
                  agents: details?.agents ?? const [],
                  isLoading: state.isDetailsLoading,
                ),
                const SizedBox(height: 30),
                _CommentsSection(
                  comments: state.comments,
                  isLoading: state.isCommentsLoading,
                  isSubmitting: state.isSubmittingComment,
                  controller: commentController,
                  onSubmit: (text) {
                    context.read<PostDetailsBloc>().add(
                      SubmitCommentEvent(
                        postId: preview.id,
                        content: text,
                      ),
                    );
                  },
                ),
                if (state.detailsError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.detailsError!,
                    style: TextStyle(color: failedColor, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 30),
                _RelatedSection(
                  posts: details?.relatedPosts ?? const [],
                  isLoading: state.isDetailsLoading,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.imageUrl, required this.height});

  final String imageUrl;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorWidget: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF111115)),
            )
          else
            const ColoredBox(color: Color(0xFF111115)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Color(0x990B0B0D),
                  Color(0xFF0B0B0D),
                ],
                stops: [0.2, 0.55, 0.78],
              ),
            ),
          ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0B0B0D)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.posterUrl,
    required this.genreNames,
    required this.faTitle,
    required this.enTitle,
    required this.imdbRate,
    required this.voteCount,
    required this.year,
    required this.duration,
    required this.summary,
    required this.likeInfo,
    required this.isDetailsLoading,
    required this.isInWatchlist,
  });

  final String posterUrl;
  final List<String> genreNames;
  final String faTitle;
  final String enTitle;
  final String imdbRate;
  final int? voteCount;
  final String year;
  final String? duration;
  final String? summary;
  final LikeInfo? likeInfo;
  final bool isDetailsLoading;
  final bool isInWatchlist;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 158,
          height: 236,
          child: _Poster(url: posterUrl),
        ),
        const SizedBox(width: 26),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (genreNames.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: genreNames
                        .map((g) => _GenreChip(label: g))
                        .toList(),
                  ),
                if (genreNames.isNotEmpty) const SizedBox(height: 10),
                Text(
                  faTitle,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                if (enTitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    enTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF444444),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _MetaRow(
                  imdbRate: imdbRate,
                  voteCount: voteCount,
                  year: year,
                  duration: duration,
                  isDetailsLoading: isDetailsLoading,
                ),
                const SizedBox(height: 20),
                _ActionButtons(isInWatchlist: isInWatchlist),
                _LikeSection(
                  likeInfo: likeInfo,
                  isLoading: isDetailsLoading,
                ),
                const SizedBox(height: 20),
                const Text(
                  'خلاصه داستان',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD0D0D8),
                  ),
                ),
                const SizedBox(height: 8),
                if (isDetailsLoading)
                  const _SummaryShimmer()
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Text(
                      (summary != null && summary!.isNotEmpty)
                          ? summary!
                          : 'خلاصه‌ای موجود نیست.',
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.9,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url});

  final String url;

  static const double _width = 158;
  static const double _height = 236;
  static const double _radius = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 64,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF111115),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: url.isEmpty
              ? const SizedBox.expand()
              : CachedNetworkImage(
                  imageUrl: url,
                  width: _width,
                  height: _height,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (_, _) =>
                      const ColoredBox(color: Color(0xFF111115)),
                  errorWidget: (_, _, _) =>
                      const ColoredBox(color: Color(0xFF111115)),
                ),
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: blueColor.withValues(alpha: 0.35)),
        color: blueColor.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: blueColor),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.imdbRate,
    required this.voteCount,
    required this.year,
    required this.duration,
    required this.isDetailsLoading,
  });

  final String imdbRate;
  final int? voteCount;
  final String year;
  final String? duration;
  final bool isDetailsLoading;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    void addDot() {
      if (items.isEmpty) return;
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('·', style: TextStyle(color: Color(0xFF1C1C22))),
        ),
      );
    }

    if (imdbRate.isNotEmpty) {
      items.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 14, color: yellowColor),
            const SizedBox(width: 5),
            Text(
              imdbRate,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Text(
              ' /10',
              style: TextStyle(fontSize: 12, color: Color(0xFF444444)),
            ),
            if (voteCount != null && voteCount! > 0)
              Text(
                '  ($voteCount)',
                style: const TextStyle(fontSize: 11, color: Color(0xFF333333)),
              )
            else if (isDetailsLoading)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: _ShimmerBox(width: 40, height: 12, radius: 4),
              ),
          ],
        ),
      );
    }

    if (year.isNotEmpty) {
      addDot();
      items.add(
        Text(
          year,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
      );
    }

    if (duration != null && duration!.isNotEmpty) {
      addDot();
      items.add(
        Text(
          duration!,
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
      );
    } else if (isDetailsLoading) {
      addDot();
      items.add(const _ShimmerBox(width: 64, height: 14, radius: 4));
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: items,
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.isInWatchlist});

  final bool isInWatchlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _PrimaryAction(
            icon: Icons.play_arrow_rounded,
            label: 'تماشا',
            onTap: () {},
          ),
          _OutlineAction(
            icon: Icons.download_rounded,
            label: 'دانلود',
            horizontalPadding: 20,
            onTap: () {},
          ),
          _OutlineAction(
            icon: isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
            label: isInWatchlist ? 'در لیست' : 'افزودن به لیست',
            horizontalPadding: 18,
            onTap: () {},
            filled: isInWatchlist,
          ),
          _OutlineAction(
            icon: Icons.favorite_border,
            label: 'افزودن به علاقه‌مندی‌ها',
            horizontalPadding: 18,
            onTap: () {},
          ),
          _IconAction(icon: Icons.share_outlined, onTap: () {}),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: blueColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'dana',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.horizontalPadding = 18,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double horizontalPadding;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? blueColor : const Color(0xFFBBBBBB);
    return Material(
      color: filled
          ? blueColor.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: filled
              ? blueColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 11,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'dana',
                  fontSize: 13,
                  color: foreground,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 15,
            color: const Color(0xFFBBBBBB),
          ),
        ),
      ),
    );
  }
}

class _LikeSection extends StatelessWidget {
  const _LikeSection({
    required this.likeInfo,
    required this.isLoading,
  });

  final LikeInfo? likeInfo;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading && likeInfo == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _ShimmerBox(width: 56, height: 14, radius: 4),
            SizedBox(width: 10),
            _ShimmerBox(width: 72, height: 34, radius: 8),
            SizedBox(width: 8),
            _ShimmerBox(width: 72, height: 34, radius: 8),
            SizedBox(width: 10),
            _ShimmerBox(width: 80, height: 14, radius: 4),
          ],
        ),
      );
    }

    final likes = likeInfo?.likes ?? 0;
    final dislikes = likeInfo?.dislikes ?? 0;
    final percent = likeInfo?.percent ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF181820)),
          bottom: BorderSide(color: Color(0xFF181820)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'رأی شما:',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF555555)),
          ),
          const SizedBox(width: 10),
          _VoteButton(
            icon: Icons.thumb_up_alt_outlined,
            count: likes,
            active: false,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _VoteButton(
            icon: Icons.thumb_down_alt_outlined,
            count: dislikes,
            active: false,
            onTap: () {},
          ),
          const SizedBox(width: 12),
          Text(
            '${percent.toStringAsFixed(0)}٪ پسند',
            style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A46)),
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: active ? blueColor : const Color(0xFF888888),
        side: BorderSide(
          color: active
              ? blueColor.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.09),
        ),
        backgroundColor: active
            ? blueColor.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: 'dana', fontSize: 13),
      ),
      icon: Icon(icon, size: 15),
      label: Text('$count'),
    );
  }
}

class _SummaryShimmer extends StatelessWidget {
  const _SummaryShimmer();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(width: double.infinity, height: 14, radius: 4),
        SizedBox(height: 8),
        _ShimmerBox(width: double.infinity, height: 14, radius: 4),
        SizedBox(height: 8),
        _ShimmerBox(width: 280, height: 14, radius: 4),
      ],
    );
  }
}

class _CastSection extends StatelessWidget {
  const _CastSection({required this.agents, required this.isLoading});

  final List<Metadata> agents;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text(
            'بازیگران',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFFE0E0E8),
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: isLoading
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (_, _) => const _CastShimmerItem(),
                  )
                : agents.isEmpty
                ? const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'بازیگری ثبت نشده است',
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: agents.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final agent = agents[index];
                      return SizedBox(
                        width: 68,
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF222230),
                                  width: 2,
                                ),
                                color: const Color(0xFF1A1A22),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: agent.avatar.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: agent.avatar,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => Center(
                                        child: Text(
                                          agent.name.isNotEmpty
                                              ? agent.name[0]
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        agent.name.isNotEmpty
                                            ? agent.name[0]
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              agent.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                            if (agent.type.isNotEmpty)
                              Text(
                                agent.type,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF38383E),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _CastShimmerItem extends StatelessWidget {
  const _CastShimmerItem();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 68,
      child: Column(
        children: [
          _ShimmerBox(width: 60, height: 60, radius: 30),
          SizedBox(height: 8),
          _ShimmerBox(width: 52, height: 10, radius: 4),
          SizedBox(height: 4),
          _ShimmerBox(width: 36, height: 8, radius: 4),
        ],
      ),
    );
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: Color(0xFF181820)),
        const SizedBox(height: 26),
        Row(
          children: [
            const Expanded(
              child: Text(
                'نظرات کاربران',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE0E0E8),
                ),
              ),
            ),
            Text(
              'همه نظرات ←',
              style: TextStyle(fontSize: 12, color: blueColor),
            ),
          ],
        ),
        const SizedBox(height: 18),
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
              SizedBox(height: 10),
              _CommentShimmerCard(),
              SizedBox(height: 10),
              _CommentShimmerCard(),
            ],
          )
        else if (comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'هنوز نظری ثبت نشده است',
              style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
            ),
          )
        else
          ...comments.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CommentCard(comment: c),
            ),
          ),
      ],
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1C1C24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blueColor.withValues(alpha: 0.35),
            ),
            alignment: Alignment.center,
            child: Text(
              TempDb.username.isNotEmpty ? TempDb.username[0] : 'ک',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 2,
              minLines: 1,
              style: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
              decoration: const InputDecoration(
                hintText: 'نظر خود را بنویسید...',
                hintStyle: TextStyle(color: Color(0xFF555555), fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    onSubmit(text);
                    controller.clear();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(
                fontFamily: 'dana',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('ارسال'),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final initial = comment.author.isNotEmpty ? comment.author[0] : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF181820)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1A1A22),
                ),
                clipBehavior: Clip.antiAlias,
                child: comment.avatar.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: comment.avatar,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.author,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                    if (comment.date.isNotEmpty)
                      Text(
                        comment.date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF333333),
                        ),
                      ),
                  ],
                ),
              ),
              if (comment.likeInfo.likes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: yellowColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: yellowColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 11, color: yellowColor),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likeInfo.likes}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: yellowColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.hasSpoil ? 'این نظر اسپویل دارد' : comment.content,
            style: TextStyle(
              fontSize: 13,
              height: 1.8,
              color: comment.hasSpoil
                  ? const Color(0xFF888888)
                  : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentShimmerCard extends StatelessWidget {
  const _CommentShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF181820)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShimmerBox(width: 36, height: 36, radius: 18),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(width: 100, height: 12, radius: 4),
                    SizedBox(height: 6),
                    _ShimmerBox(width: 60, height: 10, radius: 4),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _ShimmerBox(width: double.infinity, height: 12, radius: 4),
          SizedBox(height: 8),
          _ShimmerBox(width: 220, height: 12, radius: 4),
        ],
      ),
    );
  }
}

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({required this.posts, required this.isLoading});

  final List<Post> posts;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: Color(0xFF181820)),
        const SizedBox(height: 26),
        Row(
          children: [
            const Expanded(
              child: Text(
                'محتوای مشابه',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE0E0E8),
                ),
              ),
            ),
            Text(
              'بیشتر ←',
              style: TextStyle(fontSize: 12, color: blueColor),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 250,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: isLoading
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, _) => const _RelatedShimmerCard(),
                  )
                : posts.isEmpty
                ? const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'محتوای مشابهی یافت نشد',
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return PostWidget(
                        post: posts[index],
                        width: 138,
                        imageHeight: 207,
                        showGenre: false,
                        onClick: () {
                          context.push(
                            Routes.postDetails,
                            extra: posts[index],
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _RelatedShimmerCard extends StatelessWidget {
  const _RelatedShimmerCard();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 138,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShimmerBox(width: 138, height: 207, radius: 8),
          SizedBox(height: 7),
          _ShimmerBox(width: 100, height: 12, radius: 4),
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
