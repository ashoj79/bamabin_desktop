import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/genre.dart';
import 'package:bamabin_desktop/screen/categories/taxonomy_posts_args.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const _palette = <({Color start, Color end, Color glow})>[
    (start: Color(0xFF1A0800), end: Color(0xFF3C1800), glow: Color(0xFFFF4400)),
    (start: Color(0xFF020D15), end: Color(0xFF04182A), glow: Color(0xFF00AAFF)),
    (start: Color(0xFF0A000A), end: Color(0xFF1C0018), glow: Color(0xFF9900FF)),
    (start: Color(0xFF030A08), end: Color(0xFF091A14), glow: Color(0xFF00CC88)),
    (start: Color(0xFF100F00), end: Color(0xFF282500), glow: Color(0xFFFFCC00)),
    (start: Color(0xFF020510), end: Color(0xFF071028), glow: Color(0xFF4488FF)),
    (start: Color(0xFF050A0A), end: Color(0xFF0A1A18), glow: Color(0xFF00DDCC)),
    (start: Color(0xFF150008), end: Color(0xFF2A0018), glow: Color(0xFFFF3388)),
  ];

  @override
  Widget build(BuildContext context) {
    final genres = TempDb.genres;

    return ColoredBox(
      color: desktopBgColor,
      child: genres.isEmpty
          ? Center(
              child: Text(
                'دسته‌بندی‌ای یافت نشد',
                style: TextStyle(color: desktopMutedColor),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 14),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'دسته‌بندی‌ها',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: desktopInkColor,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisExtent: 88,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final palette = _palette[index % _palette.length];
                        return _CategoryCard(
                          genre: genres[index],
                          startColor: palette.start,
                          endColor: palette.end,
                          glowColor: palette.glow,
                        );
                      },
                      childCount: genres.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.genre,
    required this.startColor,
    required this.endColor,
    required this.glowColor,
  });

  final Genre genre;
  final Color startColor;
  final Color endColor;
  final Color glowColor;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final genre = widget.genre;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.push(
            Routes.taxonomyPosts,
            extra: TaxonomyPostsArgs(
              taxonomy: 'genres',
              id: genre.id,
              title: genre.name,
            ),
          );
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: _hovered ? 0.85 : 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF0F0F13)),
                if (genre.backgroundUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: genre.backgroundUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const SizedBox.shrink(),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [widget.startColor, widget.endColor],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.75, -0.5),
                      radius: 1.1,
                      colors: [
                        widget.glowColor.withValues(alpha: 0.16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                if (genre.backgroundUrl.isNotEmpty)
                  ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      genre.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0xB3000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
