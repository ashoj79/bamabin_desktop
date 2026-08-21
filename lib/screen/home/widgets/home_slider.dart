import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/data/remote/model/videos/slider_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class HomeSlider extends StatefulWidget {
  const HomeSlider({
    super.key,
    required this.posts,
  });

  final List<SliderPost> posts;

  @override
  State<HomeSlider> createState() => _HomeSliderState();
}

class _HomeSliderState extends State<HomeSlider> {
  final _carouselController = CarouselSliderController();
  var _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.posts.isEmpty) return const SizedBox.shrink();

    return SizedBox(
        height: 590,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: widget.posts.length,
              itemBuilder: (context, index, realIndex) {
                return _HomeSliderItem(sliderPost: widget.posts[index]);
              },
            options: CarouselOptions(
              height: 590,
              viewportFraction: 1,
              enableInfiniteScroll: widget.posts.length > 1,
              autoPlay: widget.posts.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 700),
              autoPlayCurve: Curves.easeInOut,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
          if (widget.posts.length > 1) ...[
            Positioned(
              left: 44,
              bottom: 52,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                children: [
                  _SliderArrowButton(
                    asset: 'assets/img/slider_arrow_left.svg',
                    onTap: () => _carouselController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SliderArrowButton(
                    asset: 'assets/img/slider_arrow_right.svg',
                    onTap: () => _carouselController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.posts.length, (index) {
                  final active = index == _currentIndex;
                  return GestureDetector(
                    onTap: () => _carouselController.animateToPage(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      height: 6,
                      width: active ? 20 : 6,
                      decoration: BoxDecoration(
                        color: active
                            ? blueColor
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
      );
  }
}

class _HomeSliderItem extends StatelessWidget {
  const _HomeSliderItem({required this.sliderPost});

  final SliderPost sliderPost;

  Post get post => sliderPost.post;

  String get _englishTitle =>
      post.title.isNotEmpty ? post.title : post.faTitle;

  String get _persianTitle =>
      post.title.isNotEmpty && post.faTitle.isNotEmpty ? post.faTitle : '';

  List<String> get _genreNames {
    if (post.genresId.isEmpty || TempDb.genres.isEmpty) return const [];
    final byId = {for (final g in TempDb.genres) g.id: g.name};
    return post.genresId
        .map((id) => byId[id])
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .take(3)
        .toList();
  }

  Widget _metaTag(String label) {
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

  List<Widget> _metaChildren() {
    final segments = <Widget>[];
    var needsSeparator = false;

    void addSegment(Widget child) {
      segments.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needsSeparator) ...[
              Text(
                '·',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withValues(alpha: 0.48),
                ),
              ),
              const SizedBox(width: 8),
            ],
            child,
          ],
        ),
      );
      needsSeparator = true;
    }

    if (post.imdbRate.isNotEmpty) {
      addSegment(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 13, color: yellowColor),
            const SizedBox(width: 5),
            Text(
              post.imdbRate,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              ' /10',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.33),
              ),
            ),
          ],
        ),
      );
    }

    if (post.releaseYear != '0') {
      addSegment(
        Text(
          post.releaseYear,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.47),
          ),
        ),
      );
    }

    if (sliderPost.time.isNotEmpty) {
      addSegment(
        Text(
          sliderPost.time,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.47),
          ),
        ),
      );
    }

    addSegment(_metaTag('زیرنویس فارسی'));

    if (post.hasAudio) {
      addSegment(_metaTag('دوبله فارسی'));
    }

    return segments;
  }

  /// Space reserved on the left for prev/next arrows (44 + 45+8+45 + gap).
  static const _arrowReserve = 160.0;
  static const _panelHorizontalPadding = 44.0 + 64.0;

  @override
  Widget build(BuildContext context) {
    final meta = _metaChildren();

    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderWidth = constraints.maxWidth;
        // Prefer ~55% on wide layouts; when the panel would otherwise stack
        // vertically, expand toward the arrows so info can use that space.
        final preferredPanel = sliderWidth * 0.55;
        final maxPanel = (sliderWidth - _arrowReserve).clamp(0.0, sliderWidth);
        final wouldStack = preferredPanel - _panelHorizontalPadding <
            _SliderHeroPanel._stackBreakpoint;
        final panelWidth =
            wouldStack ? maxPanel : preferredPanel.clamp(0.0, maxPanel);
        final expanded = panelWidth > preferredPanel + 1;

        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: post.bgThumbnail.isNotEmpty
                  ? post.bgThumbnail
                  : post.thumbnail,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: (context, url, error) =>
                  ColoredBox(color: desktopBgColor),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    const Color(0xB30B0B0D),
                    desktopBgColor,
                  ],
                  stops: const [0.2, 0.55, 0.8],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, desktopBgColor],
                  stops: const [0.63, 1],
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: panelWidth,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  expanded ? 24 : 44,
                  60,
                  64,
                  52,
                ),
                child: LayoutBuilder(
                  builder: (context, panelConstraints) {
                    return _SliderHeroPanel(
                      availableWidth: panelConstraints.maxWidth,
                      availableHeight: panelConstraints.maxHeight,
                      posterUrl: post.thumbnail,
                      genreNames: _genreNames,
                      englishTitle: _englishTitle,
                      persianTitle: _persianTitle,
                      meta: meta,
                      summary: sliderPost.summary,
                      post: post,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SliderHeroPanel extends StatelessWidget {
  const _SliderHeroPanel({
    required this.availableWidth,
    required this.availableHeight,
    required this.posterUrl,
    required this.genreNames,
    required this.englishTitle,
    required this.persianTitle,
    required this.meta,
    required this.summary,
    required this.post,
  });

  static const _maxPosterWidth = 308.0;
  static const _maxPosterHeight = 469.0;
  static const _posterAspect = _maxPosterWidth / _maxPosterHeight;
  static const _gap = 20.0;
  static const _minTextWidth = 200.0;
  static const _stackBreakpoint = 520.0;
  /// Approximate min height needed for titles + button (no summary/poster).
  static const _minInfoHeight = 180.0;

  final double availableWidth;
  final double availableHeight;
  final String posterUrl;
  final List<String> genreNames;
  final String englishTitle;
  final String persianTitle;
  final List<Widget> meta;
  final String summary;
  final Post post;

  ({double width, double height}) _posterSize({required bool stacked}) {
    if (stacked) {
      var width = (availableWidth * 0.42).clamp(100.0, _maxPosterWidth);
      var height = width / _posterAspect;
      // Keep room for the text block above the poster.
      final maxHeight =
          (availableHeight - _minInfoHeight - 16).clamp(0.0, height);
      if (maxHeight < 80) {
        return (width: 0, height: 0);
      }
      if (height > maxHeight) {
        height = maxHeight;
        width = height * _posterAspect;
      }
      return (width: width, height: height);
    }

    var width = (availableWidth - _gap - _minTextWidth)
        .clamp(120.0, _maxPosterWidth);
    var height = width / _posterAspect;
    final maxHeight = availableHeight * 0.92;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * _posterAspect;
    }
    return (width: width, height: height);
  }

  bool get _showPoster {
    final stacked = availableWidth < _stackBreakpoint;
    final size = _posterSize(stacked: stacked);
    return size.width >= 100 && size.height >= 80;
  }

  @override
  Widget build(BuildContext context) {
    final stacked = availableWidth < _stackBreakpoint;
    final posterSize = _posterSize(stacked: stacked);
    final showPoster = _showPoster;
    final compact = stacked || availableHeight < 420;
    final info = _SliderInfoSection(
      genreNames: genreNames,
      englishTitle: englishTitle,
      persianTitle: persianTitle,
      meta: meta,
      summary: summary,
      post: post,
      titleScale: stacked ? 0.82 : 1,
      summaryMaxLines: compact ? 2 : 3,
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.bottomStart,
              child: SizedBox(width: availableWidth, child: info),
            ),
          ),
          if (showPoster) ...[
            const SizedBox(height: 16),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _SliderPoster(
                url: posterUrl,
                width: posterSize.width,
                height: posterSize.height,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showPoster)
          _SliderPoster(
            url: posterUrl,
            width: posterSize.width,
            height: posterSize.height,
          ),
        if (showPoster) const SizedBox(width: _gap),
        Expanded(child: info),
      ],
    );
  }
}

class _SliderInfoSection extends StatelessWidget {
  const _SliderInfoSection({
    required this.genreNames,
    required this.englishTitle,
    required this.persianTitle,
    required this.meta,
    required this.summary,
    required this.post,
    this.titleScale = 1,
    this.summaryMaxLines = 3,
  });

  final List<String> genreNames;
  final String englishTitle;
  final String persianTitle;
  final List<Widget> meta;
  final String summary;
  final Post post;
  final double titleScale;
  final int summaryMaxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (genreNames.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: genreNames
                .map(
                  (g) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.67),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        if (genreNames.isNotEmpty) const SizedBox(height: 10),
        Text(
          englishTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 38 * titleScale,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
            shadows: const [
              Shadow(
                color: Color(0x80000000),
                blurRadius: 24,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        if (persianTitle.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            persianTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20 * titleScale,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ),
        ],
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 6,
              children: meta,
            ),
          ),
        ],
        if (summary.isNotEmpty && summaryMaxLines > 0) ...[
          const SizedBox(height: 10),
          Text(
            summary,
            maxLines: summaryMaxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 16,
              height: 22 / 16,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.push(Routes.postDetails, extra: post),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white.withValues(alpha: 0.8),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontFamily: 'dana',
              fontSize: 14,
            ),
          ),
          child: const Text('اطلاعات بیشتر'),
        ),
      ],
    );
  }
}

class _SliderPoster extends StatelessWidget {
  const _SliderPoster({
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final radius = (32 * (width / 308)).clamp(16.0, 32.0);

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 0.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: desktopBgColor),
              if (url.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xB30D0D0D),
                      Color(0x001A1A1A),
                      Color(0xB3000000),
                    ],
                    stops: [0, 0.46, 1],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderArrowButton extends StatelessWidget {
  const _SliderArrowButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 45,
          height: 45,
          child: Center(
            child: SvgPicture.asset(
              asset,
              width: 20,
              height: 20,
            ),
          ),
        ),
      ),
    );
  }
}
