import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/like_info.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/screen/post_details/bloc/post_details_bloc.dart';
import 'package:bamabin_desktop/screen/post_details/widgets/post_download_overlay.dart';
import 'package:bamabin_desktop/screen/post_details/widgets/post_online_play_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PostDetailsHero extends StatelessWidget {
  const PostDetailsHero({
    super.key,
    required this.postId,
    this.data,
    required this.heroUrl,
    required this.posterUrl,
    required this.genreNames,
    required this.mainTitle,
    required this.subTitle,
    required this.imdbRate,
    required this.voteCount,
    required this.duration,
    required this.summary,
    required this.hasDubbed,
    required this.hasSubtitle,
    required this.likeInfo,
    required this.likeActionLoading,
    required this.isDetailsLoading,
    required this.isInWatchlist,
    required this.isWatchlistLoading,
    required this.isSeries,
    this.movieDownloadBox,
    this.seasons = const [],
  });

  final int postId;
  final PostDetails? data;
  final String heroUrl;
  final String posterUrl;
  final List<String> genreNames;
  final String mainTitle;
  final String subTitle;
  final String imdbRate;
  final int? voteCount;
  final String? duration;
  final String? summary;
  final bool hasDubbed;
  final bool hasSubtitle;
  final LikeInfo? likeInfo;
  final String? likeActionLoading;
  final bool isDetailsLoading;
  final bool isInWatchlist;
  final bool isWatchlistLoading;
  final bool isSeries;
  final MovieDownloadBox? movieDownloadBox;
  final List<Season> seasons;

  static const _heroPadding = EdgeInsets.fromLTRB(72, 88, 72, 60);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 589),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: _HeroBackground(imageUrl: heroUrl),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _HeroTopBar(),
          ),
          Padding(
            padding: _heroPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              textDirection: TextDirection.rtl,
              children: [
                _HeroPoster(url: posterUrl),
                const SizedBox(width: 32),
                Expanded(
                  child: _HeroContent(
                    postId: postId,
                    data: data,
                    genreNames: genreNames,
                    mainTitle: mainTitle,
                    subTitle: subTitle,
                    imdbRate: imdbRate,
                    voteCount: voteCount,
                    duration: duration,
                    summary: summary,
                    hasDubbed: hasDubbed,
                    hasSubtitle: hasSubtitle,
                    likeInfo: likeInfo,
                    likeActionLoading: likeActionLoading,
                    isDetailsLoading: isDetailsLoading,
                    isInWatchlist: isInWatchlist,
                    isWatchlistLoading: isWatchlistLoading,
                    isSeries: isSeries,
                    posterUrl: posterUrl,
                    movieDownloadBox: movieDownloadBox,
                    seasons: seasons,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final initial = TempDb.username.isNotEmpty
        ? TempDb.username.characters.first
        : 'ب';
    final avatarUrl = TempDb.avatar;

    Widget avatarFallback() => Text(
          initial,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 16, 72, 0),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 54,
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              _HeaderIconButton(
                icon: Icons.arrow_back,
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(Routes.main);
                  }
                },
              ),
              const SizedBox(width: 24),
              SvgPicture.asset(
                'assets/img/bamabin_logo.svg',
                width: 140,
                height: 32,
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIconButton(
                    asset: 'assets/img/header_search.svg',
                    onTap: () => context.go(Routes.search),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: TempDb.haveUnreadNotif,
                    builder: (context, haveUnread, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _HeaderIconButton(
                            asset: 'assets/img/header_bell.svg',
                            onTap: () =>
                                context.go(Routes.notifications),
                          ),
                          if (haveUnread)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: blueColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: TempDb.isLoggedIn,
                    builder: (context, isLoggedIn, _) {
                      if (!isLoggedIn) {
                        return const _AuthButtons();
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () =>
                                  context.go(Routes.subscription),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: blueColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'dana',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('خرید اشتراک'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => context.go(Routes.profile),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    desktopAccentDarkColor,
                                    blueColor,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        blueColor.withValues(alpha: 0.24),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: avatarUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: avatarUrl,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) =>
                                          Center(child: avatarFallback()),
                                      placeholder: (context, url) =>
                                          Center(child: avatarFallback()),
                                    )
                                  : avatarFallback(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthButtons extends StatelessWidget {
  const _AuthButtons();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () => context.go(Routes.auth),
        style: ElevatedButton.styleFrom(
          backgroundColor: blueColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          textStyle: const TextStyle(
            fontFamily: 'dana',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('ورود / ثبت‌نام'),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    this.asset,
    this.icon,
    required this.onTap,
  }) : assert(asset != null || icon != null);

  final String? asset;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 45,
          height: 45,
          child: Center(
            child: asset != null
                ? SvgPicture.asset(
                    asset!,
                    width: 20,
                    height: 20,
                  )
                : Icon(
                    icon,
                    size: 20,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorWidget: (_, _, _) =>
                const ColoredBox(color: Color(0xFF0C0C14)),
          )
        else
          const ColoredBox(color: Color(0xFF0C0C14)),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF0C0C14), Color(0x00141414)],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Color(0xAE0C0C14),
                Color(0x680C0C14),
                Color(0x000C0C14),
              ],
              stops: [0, 0.58, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPoster extends StatelessWidget {
  const _HeroPoster({required this.url});

  final String url;

  static const _width = 308.0;
  static const _height = 469.0;
  static const _radius = 32.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const ColoredBox(color: Color(0xFF111115))
          : CachedNetworkImage(
              imageUrl: url,
              width: _width,
              height: _height,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              errorWidget: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF111115)),
            ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.postId,
    this.data,
    required this.genreNames,
    required this.mainTitle,
    required this.subTitle,
    required this.imdbRate,
    required this.voteCount,
    required this.duration,
    required this.summary,
    required this.hasDubbed,
    required this.hasSubtitle,
    required this.likeInfo,
    required this.likeActionLoading,
    required this.isDetailsLoading,
    required this.isInWatchlist,
    required this.isWatchlistLoading,
    required this.isSeries,
    required this.posterUrl,
    this.movieDownloadBox,
    this.seasons = const [],
  });

  final int postId;
  final PostDetails? data;
  final List<String> genreNames;
  final String mainTitle;
  final String subTitle;
  final String imdbRate;
  final int? voteCount;
  final String? duration;
  final String? summary;
  final bool hasDubbed;
  final bool hasSubtitle;
  final LikeInfo? likeInfo;
  final String? likeActionLoading;
  final bool isDetailsLoading;
  final bool isInWatchlist;
  final bool isWatchlistLoading;
  final bool isSeries;
  final String posterUrl;
  final MovieDownloadBox? movieDownloadBox;
  final List<Season> seasons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (genreNames.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.start,
            children: genreNames.map((g) => _BrandTag(label: g)).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (mainTitle.isNotEmpty)
          Text(
            mainTitle,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 48 / 40,
              letterSpacing: -0.3,
            ),
          ),
        if (subTitle.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            subTitle,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.48),
              height: 24 / 20,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _HeroMetaRow(
          imdbRate: imdbRate,
          voteCount: voteCount,
          duration: duration,
          hasDubbed: hasDubbed,
          hasSubtitle: hasSubtitle,
          isDetailsLoading: isDetailsLoading,
        ),
        const SizedBox(height: 12),
        if (isDetailsLoading && (summary == null || summary!.isEmpty))
          const _SummaryShimmer()
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              summary != null && summary!.isNotEmpty
                  ? 'خلاصه داستان: $summary'
                  : 'خلاصه‌ای موجود نیست.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                height: 22 / 16,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: -0.18,
              ),
            ),
          ),
        const SizedBox(height: 12),
        _HeroLikeRow(
          postId: postId,
          likeInfo: likeInfo,
          likeActionLoading: likeActionLoading,
          isLoading: isDetailsLoading,
        ),
        const SizedBox(height: 12),
        _HeroActionRow(
          postId: postId,
          data: data,
          title: mainTitle,
          posterUrl: posterUrl,
          isLoading: isDetailsLoading,
          isInWatchlist: isInWatchlist,
          isWatchlistLoading: isWatchlistLoading,
          isSeries: isSeries,
          movieDownloadBox: movieDownloadBox,
          seasons: seasons,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _BrandTag extends StatelessWidget {
  const _BrandTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: blueColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: blueColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: blueColor,
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.48)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _HeroMetaRow extends StatelessWidget {
  const _HeroMetaRow({
    required this.imdbRate,
    required this.voteCount,
    required this.duration,
    required this.hasDubbed,
    required this.hasSubtitle,
    required this.isDetailsLoading,
  });

  final String imdbRate;
  final int? voteCount;
  final String? duration;
  final bool hasDubbed;
  final bool hasSubtitle;
  final bool isDetailsLoading;

  static String _formatVoteCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return k >= 10 ? '${k.round()}k' : '${k.toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    void addDot() {
      if (items.isEmpty) return;
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '·',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ),
        ),
      );
    }

    if (hasDubbed) {
      addDot();
      items.add(const _MetaTag(label: 'دوبله فارسی'));
    }

    if (hasSubtitle) {
      addDot();
      items.add(const _MetaTag(label: 'زیرنویس فارسی'));
    }

    if (duration != null && duration!.isNotEmpty) {
      addDot();
      items.add(_MetaTag(label: duration!));
    } else if (isDetailsLoading) {
      addDot();
      items.add(const _ShimmerBox(width: 72, height: 28, radius: 6));
    }

    if (imdbRate.isNotEmpty) {
      addDot();
      items.add(
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: imdbRate,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFBBF24),
                  letterSpacing: -0.15,
                ),
              ),
              TextSpan(
                text: voteCount != null && voteCount! > 0
                    ? '/10  (${_formatVoteCount(voteCount!)})'
                    : '/10',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.48),
                  letterSpacing: -0.16,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (isDetailsLoading) {
      items.add(const _ShimmerBox(width: 120, height: 24, radius: 4));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: items,
    );
  }
}

class _HeroLikeRow extends StatelessWidget {
  const _HeroLikeRow({
    required this.postId,
    required this.likeInfo,
    required this.likeActionLoading,
    required this.isLoading,
  });

  final int postId;
  final LikeInfo? likeInfo;
  final String? likeActionLoading;
  final bool isLoading;

  void _onVote(BuildContext context, String action) {
    if (likeActionLoading != null) return;
    context.read<PostDetailsBloc>().add(
          LikePostEvent(postId: postId, action: action),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && likeInfo == null) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _ShimmerBox(width: 72, height: 40, radius: 12),
          SizedBox(width: 8),
          _ShimmerBox(width: 72, height: 40, radius: 12),
          SizedBox(width: 8),
          _ShimmerBox(width: 80, height: 28, radius: 6),
        ],
      );
    }

    final likes = likeInfo?.likes ?? 0;
    final dislikes = likeInfo?.dislikes ?? 0;
    final percent = likeInfo?.percent ?? 0;
    final busy = likeActionLoading != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const _VoteLabel(label: 'رای شما:'),
        const SizedBox(width: 8),
        _VoteChip(
          svgAsset: 'assets/img/hero_like.svg',
          count: likes,
          isLoading: likeActionLoading == 'like',
          enabled: !busy,
          onTap: () => _onVote(context, 'like'),
        ),
        const SizedBox(width: 8),
        _VoteChip(
          svgAsset: 'assets/img/hero_dislike.svg',
          count: dislikes,
          isLoading: likeActionLoading == 'dislike',
          enabled: !busy,
          onTap: () => _onVote(context, 'dislike'),
        ),
        const SizedBox(width: 8),
        _VoteLabel(label: '${percent.toStringAsFixed(0)}% پسند'),
      ],
    );
  }
}

class _VoteLabel extends StatelessWidget {
  const _VoteLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: Colors.white.withValues(alpha: 0.75),
      ),
    );
  }
}

class _VoteChip extends StatelessWidget {
  const _VoteChip({
    required this.svgAsset,
    required this.count,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  });

  final String svgAsset;
  final int count;
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white.withValues(alpha: 0.75);

    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        onTap: enabled && !isLoading ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 12,
            end: 16,
            top: 8,
            bottom: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: blueColor,
                  ),
                )
              else
                SvgPicture.asset(
                  svgAsset,
                  width: 24,
                  height: 24,
                ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: -0.18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroActionRow extends StatelessWidget {
  const _HeroActionRow({
    required this.postId,
    this.data,
    required this.title,
    required this.posterUrl,
    required this.isLoading,
    required this.isInWatchlist,
    required this.isWatchlistLoading,
    required this.isSeries,
    this.movieDownloadBox,
    this.seasons = const [],
  });

  final int postId;
  final PostDetails? data;
  final String title;
  final String posterUrl;
  final bool isLoading;
  final bool isInWatchlist;
  final bool isWatchlistLoading;
  final bool isSeries;
  final MovieDownloadBox? movieDownloadBox;
  final List<Season> seasons;

  void _openDownload(BuildContext context) {
    showPostDownloadOverlay(
      context,
      isSeries: isSeries,
      title: title,
      posterUrl: posterUrl,
      movieDownloadBox: movieDownloadBox,
      seasons: seasons,
    );
  }

  void _openOnlinePlay(BuildContext context) {
    showPostOnlinePlayOverlay(
      context,
      data: data,
      isSeries: isSeries,
      title: title,
      movieDownloadBox: movieDownloadBox,
      seasons: seasons,
    );
  }

  void _toggleWatchlist(BuildContext context) {
    if (isWatchlistLoading) return;
    if (!TempDb.isLoggedIn.value) {
      showBamabinSnackbar(
        context,
        'برای افزودن به علاقه‌مندی‌ها ابتدا وارد حساب کاربری شوید',
      );
      return;
    }
    context.read<PostDetailsBloc>().add(
          ToggleWatchlistEvent(postId: postId),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ShimmerBox(width: 168, height: 48, radius: 16),
          _ShimmerBox(width: 148, height: 48, radius: 16),
          _ShimmerBox(width: 112, height: 48, radius: 16),
          _ShimmerBox(width: 136, height: 48, radius: 16),
          _ShimmerBox(width: 196, height: 48, radius: 16),
          _ShimmerBox(width: 48, height: 48, radius: 16),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _PrimaryHeroButton(
          label: 'تماشای آنلاین',
          svgAsset: 'assets/img/hero_play_circle.svg',
          onTap: () => _openOnlinePlay(context),
        ),
        if (isSeries)
          _SecondaryHeroButton(
            label: 'لیست قسمت ها',
            svgAsset: 'assets/img/hero_video_library.svg',
            onTap: () => _openOnlinePlay(context),
          ),
        _SecondaryHeroButton(
          label: 'دانلود',
          svgAsset: 'assets/img/hero_download.svg',
          onTap: () => _openDownload(context),
        ),
        _SecondaryHeroButton(
          label: 'افزودن به علاقه مندی ها',
          svgAsset: isInWatchlist
              ? 'assets/img/hero_heart_filled.svg'
              : 'assets/img/hero_heart.svg',
          isLoading: isWatchlistLoading,
          onTap: () => _toggleWatchlist(context),
        ),
        _IconHeroButton(
          svgAsset: 'assets/img/hero_share.svg',
          onTap: () {},
        ),
      ],
    );
  }
}

class _PrimaryHeroButton extends StatelessWidget {
  const _PrimaryHeroButton({
    required this.label,
    required this.svgAsset,
    required this.onTap,
  });

  final String label;
  final String svgAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: blueColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 24, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              SvgPicture.asset(
                svgAsset,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryHeroButton extends StatelessWidget {
  const _SecondaryHeroButton({
    required this.label,
    required this.onTap,
    required this.svgAsset,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final String svgAsset;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.48)),
      ),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: blueColor,
                  ),
                )
              else
                SvgPicture.asset(
                  svgAsset,
                  width: 24,
                  height: 24,
                ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.75),
                  letterSpacing: -0.18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconHeroButton extends StatelessWidget {
  const _IconHeroButton({required this.svgAsset, required this.onTap});

  final String svgAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.48)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: SvgPicture.asset(
              svgAsset,
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
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
        _ShimmerBox(width: 500, height: 16, radius: 4),
        SizedBox(height: 8),
        _ShimmerBox(width: 420, height: 16, radius: 4),
        SizedBox(height: 8),
        _ShimmerBox(width: 280, height: 16, radius: 4),
      ],
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
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A22),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
