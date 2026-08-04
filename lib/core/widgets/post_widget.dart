import 'dart:ui';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class PostWidget extends StatefulWidget {
  const PostWidget({
    super.key,
    required this.post,
    this.onClick,
    this.onDeleteTap,
    this.width = 148,
    this.imageHeight = 222,
    this.showGenre = true,
  });

  final Post post;
  final VoidCallback? onClick;
  final VoidCallback? onDeleteTap;
  final double width;
  final double imageHeight;
  final bool showGenre;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  var _hovered = false;
  Offset? _pointerDown;

  Post get post => widget.post;

  String get _genreLabel {
    if (post.genresId.isEmpty || TempDb.genres.isEmpty) return '';
    final byId = {for (final g in TempDb.genres) g.id: g.name};
    final names = <String>[];
    for (final id in post.genresId) {
      final name = byId[id];
      if (name != null && name.isNotEmpty) {
        names.add(name);
        if (names.length >= 2) break;
      }
    }
    return names.join('، ');
  }

  void _handleTap() {
    final onClick = widget.onClick;
    if (onClick != null) {
      onClick();
      return;
    }
    context.push(Routes.postDetails, extra: post);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Listener(
        onPointerDown: (event) => _pointerDown = event.localPosition,
        onPointerUp: (event) {
          final down = _pointerDown;
          _pointerDown = null;
          if (down == null) return;
          if ((event.localPosition - down).distance <= 8) {
            _handleTap();
          }
        },
        onPointerCancel: (_) => _pointerDown = null,
        child: SizedBox(
          width: widget.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Poster(
                post: post,
                width: widget.width,
                height: widget.imageHeight,
                hovered: _hovered,
                onDeleteTap: widget.onDeleteTap,
              ),
              const SizedBox(height: 8),
              Text(
                post.faTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: desktopInkColor,
                ),
              ),
              if (widget.showGenre && _genreLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _genreLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.post,
    required this.width,
    required this.height,
    required this.hovered,
    this.onDeleteTap,
  });

  final Post post;
  final double width;
  final double height;
  final bool hovered;
  final VoidCallback? onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final showSummary = hovered && post.summary.isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF111115)),
            CachedNetworkImage(
              imageUrl: post.thumbnail,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.46, 1],
                  colors: [
                    Color(0xB30D0D0D),
                    Color(0x0A1A1A1A),
                    Color(0xB3000000),
                  ],
                ),
              ),
            ),
            if (post.imdbRate.isNotEmpty)
              Positioned(
                top: onDeleteTap != null ? 36 : 10,
                left: 10,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: post.imdbRate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 20 / 14,
                            letterSpacing: -0.16,
                            color: Color(0xFFF1F5F9),
                          ),
                        ),
                        const TextSpan(
                          text: '/10',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            height: 10 / 9,
                            color: Color(0xFFF1F5F9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 5,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _BadgeIcon(asset: 'assets/img/post_subtitle.svg'),
                    if (post.hasAudio) ...[
                      const SizedBox(width: 2),
                      const _BadgeIcon(asset: 'assets/img/post_dubbed.svg'),
                    ],
                  ],
                ),
              ),
            ),
            if (onDeleteTap != null)
              Positioned(
                top: 4,
                left: 4,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: onDeleteTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline,
                        color: redColor,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            if (post.title.isNotEmpty)
              Positioned(
                left: 10,
                right: 10,
                bottom: 9,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (post.summary.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                    tween: Tween(end: showSummary ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      if (value == 0) return const SizedBox.shrink();
                      return Opacity(
                        opacity: value,
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 10 * value,
                            sigmaY: 10 * value,
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        child: Center(
                          child: Text(
                            post.summary,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              height: 1.55,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xB3131321),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          width: 0.5,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: SvgPicture.asset(
        asset,
        width: 16,
        height: 16,
      ),
    );
  }
}
