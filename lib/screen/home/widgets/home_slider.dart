import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/data/remote/model/videos/slider_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeSlider extends StatefulWidget {
  const HomeSlider({super.key, required this.posts});

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
              left: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: _SliderArrowButton(
                  icon: Icons.chevron_right,
                  onTap: () => _carouselController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: _SliderArrowButton(
                  icon: Icons.chevron_left,
                  onTap: () => _carouselController.previousPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  ),
                ),
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

  String get _displayTitle =>
      post.faTitle.isNotEmpty ? post.faTitle : post.title;

  String get _englishTitle =>
      post.faTitle.isNotEmpty && post.title.isNotEmpty ? post.title : '';

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

  List<Widget> _metaChildren() {
    final children = <Widget>[];

    void addDot() {
      if (children.isEmpty) return;
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '·',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.13)),
          ),
        ),
      );
    }

    if (post.imdbRate.isNotEmpty) {
      children.addAll([
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
      ]);
    }

    if (post.releaseYear != '0') {
      addDot();
      children.add(
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
      addDot();
      children.add(
        Text(
          sliderPost.time,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.47),
          ),
        ),
      );
    }

    if (post.hasAudio) {
      addDot();
      children.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            'دوبله',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.33),
            ),
          ),
        ),
      );
    }

    return children;
  }

  @override
  Widget build(BuildContext context) {
    final meta = _metaChildren();

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
          errorWidget: (context, url, error) => ColoredBox(color: desktopBgColor),
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
          width: MediaQuery.sizeOf(context).width * 0.55,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(44, 60, 64, 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_genreNames.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _genreNames
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
                if (_genreNames.isNotEmpty) const SizedBox(height: 10),
                Text(
                  _displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Color(0x80000000),
                        blurRadius: 24,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (_englishTitle.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _englishTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.27),
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: meta,
                    ),
                  ),
                ],
                if (sliderPost.summary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Text(
                      sliderPost.summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.85,
                        color: Colors.white.withValues(alpha: 0.53),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.push(Routes.postDetails, extra: post),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'dana',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('تماشا'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () =>
                          context.push(Routes.postDetails, extra: post),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.8),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.07),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderArrowButton extends StatelessWidget {
  const _SliderArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0x1AFFFFFF)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: const Color(0xFFCCCCCC)),
        ),
      ),
    );
  }
}
