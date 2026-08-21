import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

const _cardRadius = 24.0;
const _cardStrokeWidth = 2.0;
const _artworkColor = Color(0xFF131321);

class Top250Card extends StatefulWidget {
  const Top250Card({
    super.key,
    required this.post,
    required this.rank,
  });

  final Post post;
  final int rank;

  @override
  State<Top250Card> createState() => _Top250CardState();
}

class _Top250CardState extends State<Top250Card> {
  var _hovered = false;

  Post get post => widget.post;

  String get _title {
    if (post.title.isNotEmpty) return post.title;
    return post.faTitle;
  }

  String get _bgUrl {
    if (post.bgThumbnail.isNotEmpty) return post.bgThumbnail;
    return post.thumbnail;
  }

  List<String> get _genreNames {
    if (post.genresId.isEmpty || TempDb.genres.isEmpty) return const [];
    final byId = {for (final g in TempDb.genres) g.id: g.name};
    return post.genresId
        .map((id) => byId[id])
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .take(4)
        .toList();
  }

  String? get _yearLabel {
    final year = post.releaseYear;
    if (year == '0' || year.isEmpty) return null;
    return year;
  }

  bool get _isAvailable => post.id != 0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: _isAvailable
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: _isAvailable
            ? () => context.push(Routes.postDetails, extra: post)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_cardRadius),
            boxShadow: _hovered && _isAvailable
                ? [
                    BoxShadow(
                      color: blueColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          // The stroke is centered on the card edge, so the artwork covers its
          // inner half and only a hairline remains visible, as in the design.
          child: CustomPaint(
            painter: _CardBorderPainter(
              color: Colors.white.withValues(alpha: 0.6),
            ),
            foregroundPainter:
                _hovered && _isAvailable
                    ? _CardBorderPainter(color: blueColor)
                    : null,
            child: Padding(
              padding: const EdgeInsets.all(_cardStrokeWidth / 2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  _cardRadius - _cardStrokeWidth / 2,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_bgUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: _bgUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) =>
                            const ColoredBox(color: _artworkColor),
                      )
                    else
                      const ColoredBox(color: _artworkColor),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [Color(0x660C0C14), _artworkColor],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          _PosterWithRank(
                            thumbnail: post.thumbnail,
                            rank: widget.rank,
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_genreNames.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    textDirection: TextDirection.rtl,
                                    children: _genreNames
                                        .map((g) => _Tag(label: g))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    _title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _MetaRow(
                                  imdbRate: post.imdbRate,
                                  yearLabel: _yearLabel,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBorderPainter extends CustomPainter {
  const _CardBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = _cardStrokeWidth / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          inset,
          inset,
          size.width - _cardStrokeWidth,
          size.height - _cardStrokeWidth,
        ),
        const Radius.circular(_cardRadius - inset),
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _cardStrokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _CardBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PosterWithRank extends StatelessWidget {
  const _PosterWithRank({
    required this.thumbnail,
    required this.rank,
  });

  final String thumbnail;
  final int rank;

  static const _posterW = 91.0;
  static const _posterH = 136.0;
  static const _badgeSize = 32.0;
  static const _badgeOverlap = 16.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _posterW,
      height: _posterH + _badgeOverlap,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: _badgeOverlap,
            left: 0,
            right: 0,
            child: Container(
              height: _posterH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 12.8,
                    offset: Offset(-12, 0),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: thumbnail.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: thumbnail,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          const ColoredBox(color: Color(0xFF1C1C2B)),
                    )
                  : const ColoredBox(color: Color(0xFF1C1C2B)),
            ),
          ),
          Container(
            width: _badgeSize,
            height: _badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: blueColor,
              borderRadius: BorderRadius.circular(37),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF0F9FF),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          height: 16 / 12,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.imdbRate,
    required this.yearLabel,
  });

  final String imdbRate;
  final String? yearLabel;

  @override
  Widget build(BuildContext context) {
    // LTR row, start-aligned in RTL → rating sits next to the poster.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (yearLabel != null) _Tag(label: yearLabel!),
            if (yearLabel != null && imdbRate.isNotEmpty)
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
            if (imdbRate.isNotEmpty)
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
                        height: 30 / 24,
                      ),
                    ),
                    TextSpan(
                      text: '/10',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.48),
                        letterSpacing: -0.16,
                      ),
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

class Top250CardShimmer extends StatelessWidget {
  const Top250CardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _artworkColor,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Shimmer(
            color: Colors.white,
            child: Container(
              width: 91,
              height: 136,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 24),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 180, height: 24, radius: 24),
                SizedBox(height: 8),
                _ShimmerBox(width: 220, height: 28, radius: 6),
                SizedBox(height: 8),
                _ShimmerBox(width: 120, height: 24, radius: 6),
              ],
            ),
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
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
