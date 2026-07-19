import 'package:bamabin_desktop/config/dimens.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:flutter/material.dart';
import 'package:bamabin_desktop/core/widgets/post_widget.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PostsGrid extends StatelessWidget {
  final List<Post> posts;
  final VoidCallback onLoadMore;
  final bool allowLoading;
  final Function(int)? onDelete, onClick;

  const PostsGrid({
    super.key,
    required this.posts,
    required this.onLoadMore,
    this.allowLoading = true,
    this.onDelete,
    this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    var width = mediaQuery.size.width;
    var aspectRatio = 180 / 140;
    var itemWidth = (width - 32) / 3;
    var itemHeight = itemWidth * aspectRatio;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.71,
        mainAxisSpacing: 8,
      ),
      itemCount: posts.isEmpty && allowLoading ? 9 : posts.length,
      itemBuilder: (context, index) {
        if (posts.isEmpty && allowLoading) {
          return _ShimmerWidget();
        }

        if (index == posts.length - 1) {
          onLoadMore();
        }
        return PostWidget(
          post: posts[index],
          onDeleteTap: onDelete != null
              ? () => onDelete!(posts[index].id)
              : null,
          onClick: onClick != null ? () => onClick!(posts[index].id) : null,
          imageHeight: itemHeight,
        );
      },
    );
  }
}

class _ShimmerWidget extends StatelessWidget {
  const _ShimmerWidget();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: 140,
        height: 180,
        margin: EdgeInsets.symmetric(horizontal: paddingSmall),
      ),
    );
  }
}
