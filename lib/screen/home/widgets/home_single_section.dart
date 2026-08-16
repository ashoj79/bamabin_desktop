import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/home_sections.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/data/remote/model/videos/single_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class HomeSingleSection extends StatelessWidget {
  const HomeSingleSection({
    super.key,
    required this.section,
  });

  final SingleSection section;

  SinglePost? get _post => section.post;

  Post? get _main => _post?.mainData;

  String get _title {
    final main = _main;
    if (main == null) return '';
    if (main.title.isNotEmpty) return main.title;
    if (_post!.title.isNotEmpty) return _post!.title;
    return main.faTitle;
  }

  String get _summary {
    final post = _post;
    if (post == null) return '';
    if (post.summary.isNotEmpty) return post.summary;
    return post.mainData.summary;
  }

  String get _imageUrl {
    final main = _main;
    if (main == null) return '';
    if (main.bgThumbnail.isNotEmpty) return main.bgThumbnail;
    return main.thumbnail;
  }

  List<String> get _genreNames {
    final main = _main;
    if (main == null || main.genresId.isEmpty || TempDb.genres.isEmpty) {
      return const [];
    }
    final byId = {for (final g in TempDb.genres) g.id: g.name};
    return main.genresId
        .map((id) => byId[id])
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .take(4)
        .toList();
  }

  void _openDetails(BuildContext context) {
    final main = _main;
    if (main == null) return;
    context.push(Routes.postDetails, extra: main);
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post == null || _main == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 371,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: _imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: (context, url, error) =>
                  ColoredBox(color: desktopBgColor),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0C0C14),
                    Color(0x800C0C14),
                    Color(0xFF0C0C14),
                  ],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    const Color(0xFF141414),
                    const Color(0xFF0C0C14).withValues(alpha: 0),
                  ],
                  stops: const [0, 0.2],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(72, 60, 72, 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_title.isNotEmpty)
                    Text(
                      _title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        height: 48 / 40,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                    ),
                  if (_genreNames.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: _genreNames
                          .map(
                            (g) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.48),
                                ),
                              ),
                              child: Text(
                                g,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (_summary.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Text(
                        _summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 16,
                          height: 22 / 16,
                          letterSpacing: -0.18,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _PlayOnlineButton(
                        onTap: () => _openDetails(context),
                      ),
                      const SizedBox(width: 8),
                      _MoreInfoButton(onTap: () => _openDetails(context)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayOnlineButton extends StatelessWidget {
  const _PlayOnlineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: blueColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: InkWell(
          canRequestFocus: false,
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 16,
              end: 24,
              top: 12,
              bottom: 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PlayCircleIcon(size: 24),
                const SizedBox(width: 8),
                const Text(
                  'پخش آنلاین',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _MoreInfoButton extends StatelessWidget {
  const _MoreInfoButton({required this.onTap});

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
          canRequestFocus: false,
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'اطلاعات بیشتر',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.18,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      );
  }
}

/// Solar play-circle bold-duotone from Figma (outer + inner assets).
class _PlayCircleIcon extends StatelessWidget {
  const _PlayCircleIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * 0.0833),
              child: SvgPicture.asset(
                'assets/img/play_circle_outer.svg',
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            left: size * 0.375,
            top: size * 0.3334,
            right: size * 0.3333,
            bottom: size * 0.3333,
            child: SvgPicture.asset(
              'assets/img/play_circle_inner.svg',
              fit: BoxFit.fill,
            ),
          ),
        ],
      ),
    );
  }
}
