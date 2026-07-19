import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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

  String get _displayTitle =>
      post.faTitle.isNotEmpty ? post.faTitle : post.title;

  String get _genreLabel {
    if (post.genresId.isEmpty || TempDb.genres.isEmpty) return '';
    final byId = {for (final g in TempDb.genres) g.id: g.name};
    for (final id in post.genresId) {
      final name = byId[id];
      if (name != null && name.isNotEmpty) return name;
    }
    return '';
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
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 0.88 : 1,
          child: SizedBox(
            width: widget.width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: widget.width,
                    height: widget.imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0xFF111115)),
                        CachedNetworkImage(
                          imageUrl: post.thumbnail,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const SizedBox.shrink(),
                        ),
                        if (post.imdbRate.isNotEmpty)
                          Positioned(
                            top: 7,
                            right: 7,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 8,
                                      color: yellowColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      post.imdbRate,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: desktopInkColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (widget.onDeleteTap != null)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(6),
                              child: InkWell(
                                onTap: widget.onDeleteTap,
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
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(10, 22, 10, 9),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0xBF000000),
                                ],
                              ),
                            ),
                            child: Text(
                              _displayTitle,
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
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _hovered ? 1 : 0,
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.25),
                            child: Center(
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: blueColor.withValues(alpha: 0.88),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.67),
                  ),
                ),
                if (widget.showGenre && _genreLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _genreLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF3A3A46),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
