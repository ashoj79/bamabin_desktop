import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/post_widget.dart';
import 'package:bamabin_desktop/core/widgets/view_all_button.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/screen/post_details/bloc/post_details_bloc.dart';
import 'package:bamabin_desktop/screen/post_details/widgets/post_details_comments.dart';
import 'package:bamabin_desktop/screen/post_details/widgets/post_details_hero.dart';
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
      child: BlocConsumer<PostDetailsBloc, PostDetailsState>(
        listenWhen: (previous, current) {
          if (current is! PostDetailsViewState) return false;
          if (previous is! PostDetailsViewState) {
            return current.likeError != null || current.watchlistError != null;
          }
          return (current.likeError != null &&
                  current.likeError != previous.likeError) ||
              (current.watchlistError != null &&
                  current.watchlistError != previous.watchlistError);
        },
        listener: (context, state) {
          if (state is! PostDetailsViewState) return;
          final message = state.likeError ?? state.watchlistError;
          if (message != null) {
            showBamabinSnackbar(context, message);
          }
        },
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

  String get _mainTitle {
    final title = details?.title ?? preview.title;
    if (title.isNotEmpty) return title;
    return preview.faTitle;
  }

  String get _subTitle {
    final fa = details?.faTitle ?? preview.faTitle;
    if (fa.isNotEmpty && fa != _mainTitle) return fa;
    return '';
  }

  bool get _hasDubbed => details?.hasDubbed ?? preview.hasAudio;

  bool get _hasSubtitle => details?.hasSubtitle ?? true;

  bool get _isSeries => details?.isSeries ?? false;

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostDetailsHero(
            postId: preview.id,
            data: details,
            heroUrl: _heroUrl,
            posterUrl: _posterUrl,
            genreNames: _genreNames,
            mainTitle: _mainTitle,
            subTitle: _subTitle,
            imdbRate: _imdbRate,
            voteCount: details?.imdbVoteCount,
            duration: details?.getTime(),
            summary: details?.summary,
            hasDubbed: _hasDubbed,
            hasSubtitle: _hasSubtitle,
            likeInfo: details?.likeInfo,
            likeActionLoading: state.likeActionLoading,
            isDetailsLoading: state.isDetailsLoading,
            isInWatchlist: details?.isInWatchlist ?? false,
            isWatchlistLoading: state.isWatchlistLoading,
            isSeries: _isSeries,
            movieDownloadBox: details?.movieDownloadBox,
            seasons: details?.seasons ?? const [],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 34, 72, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CastSection(
                  agents: details?.agents ?? const [],
                  isLoading: state.isDetailsLoading,
                ),
                const SizedBox(height: 30),
                PostDetailsCommentsSection(
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
                  postType: details?.postType,
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

class _CastSection extends StatelessWidget {
  const _CastSection({required this.agents, required this.isLoading});

  final List<Metadata> agents;
  final bool isLoading;

  static const _listHeight = 180.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'لیست بازیگران',
          textAlign: TextAlign.start,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 24 / 20,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: _listHeight,
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
                    itemCount: 8,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (_, _) => const _CastShimmerItem(),
                  )
                : agents.isEmpty
                ? const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'بازیگری ثبت نشده است',
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: agents.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (context, index) =>
                        _CastItem(agent: agents[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CastItem extends StatelessWidget {
  const _CastItem({required this.agent});

  final Metadata agent;

  static const _avatarSize = 120.0;
  static const _itemWidth = 120.0;

  static String _localizedType(String type) {
    switch (type.toLowerCase()) {
      case 'actor':
        return 'بازیگر';
      case 'director':
        return 'کارگردان';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = agent.name.isNotEmpty ? agent.name[0] : '?';
    final typeLabel = _localizedType(agent.type);

    return SizedBox(
      width: _itemWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
              ),
              color: const Color(0xFF1A1A22),
            ),
            clipBehavior: Clip.antiAlias,
            child: agent.avatar.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: agent.avatar,
                    width: _avatarSize,
                    height: _avatarSize,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _CastInitial(initial: initial),
                  )
                : _CastInitial(initial: initial),
          ),
          const SizedBox(height: 12),
          Text(
            agent.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          if (typeLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              typeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.48),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CastInitial extends StatelessWidget {
  const _CastInitial({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CastShimmerItem extends StatelessWidget {
  const _CastShimmerItem();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 120,
      child: Column(
        children: [
          _ShimmerBox(width: 120, height: 120, radius: 60),
          SizedBox(height: 12),
          _ShimmerBox(width: 96, height: 14, radius: 4),
          SizedBox(height: 4),
          _ShimmerBox(width: 64, height: 12, radius: 4),
        ],
      ),
    );
  }
}

class _RelatedSection extends StatelessWidget {
  const _RelatedSection({
    required this.posts,
    required this.isLoading,
    this.postType,
  });

  final List<Post> posts;
  final bool isLoading;
  final String? postType;

  void _onViewAll(BuildContext context) {
    if (postType == null || postType!.isEmpty) return;
    context.push(
      Routes.postTypeArchive,
      extra: {
        'postTypes': postType,
        'title': 'محتوای مشابه',
      },
    );
  }

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
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF0F0F4),
                ),
              ),
            ),
            if (!isLoading && posts.isNotEmpty)
              ViewAllButton(onPressed: () => _onViewAll(context)),
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
                    alignment: AlignmentDirectional.centerStart,
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
