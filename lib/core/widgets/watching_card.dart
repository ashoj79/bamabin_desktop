import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/remote/model/user/play_status.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

const _surface = Color(0xFF14141F);
const _field = Color(0xFF1C1C2B);
const _muted = Color(0xFFA8AABB);
const _ink = Color(0xFFF4F4F8);

class WatchingCard extends StatelessWidget {
  const WatchingCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final PlayStatus item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final post = item.post;
    final title = post.faTitle.isNotEmpty ? post.faTitle : post.title;
    final image =
        post.bgThumbnail.isNotEmpty ? post.bgThumbnail : post.thumbnail;
    final progress = (item.watchPercentage / 100).clamp(0.0, 1.0);
    final subtitle =
        item.remainingTime.isNotEmpty ? '${item.remainingTime} مانده' : '';

    return Material(
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => context.push(Routes.postDetails, extra: post),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (image.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const _WatchingShimmerBox(
                        width: double.infinity,
                        height: double.infinity,
                        radius: 0,
                      ),
                    )
                  else
                    const ColoredBox(color: _field),
                  Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0A0A12).withValues(alpha: 0.55),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 4,
                      color: Colors.white.withValues(alpha: 0.15),
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: ColoredBox(color: blueColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WatchingCardShimmer extends StatelessWidget {
  const WatchingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Expanded(
            child: _WatchingShimmerBox(
              width: double.infinity,
              height: double.infinity,
              radius: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _WatchingShimmerBox(width: 120, height: 14, radius: 4),
                SizedBox(height: 8),
                _WatchingShimmerBox(width: 80, height: 11, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchingShimmerBox extends StatelessWidget {
  const _WatchingShimmerBox({
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
