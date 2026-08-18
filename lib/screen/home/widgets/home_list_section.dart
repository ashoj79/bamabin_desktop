import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/post_widget.dart';
import 'package:bamabin_desktop/core/widgets/view_all_button.dart';
import 'package:bamabin_desktop/data/remote/model/videos/home_sections.dart';
import 'package:bamabin_desktop/screen/categories/taxonomy_posts_args.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';

class HomeListSection extends StatelessWidget {
  const HomeListSection({
    super.key,
    required this.section,
  });

  final ListSection section;

  void _onMoreClick(BuildContext context) {
    final taxonomy = section.taxonomy;
    final taxonomyId = int.tryParse(section.taxonomyId ?? '');
    if (taxonomy != null &&
        taxonomy.isNotEmpty &&
        taxonomyId != null &&
        taxonomyId > 0) {
      context.push(
        Routes.taxonomyPosts,
        extra: TaxonomyPostsArgs(
          taxonomy: taxonomy,
          id: taxonomyId,
          title: section.name,
        ),
      );
      return;
    }

    context.push(
      Routes.taxonomyPosts,
      extra: TaxonomyPostsArgs.archive(
        title: section.name,
        archiveType: section.postTypes.join(','),
        broadcastStatus: section.broadcastStatuses.join(','),
        dlboxType: section.dlboxType,
        miniSerial: section.miniSerial ? 'on' : '',
        free: section.isFree ? 'on' : '',
        dubbed: section.isDubbed ? 'on' : '',
        orderBy: section.orderBy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (section.posts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: desktopInkColor,
                    ),
                  ),
                ),
                ViewAllButton(onPressed: () => _onMoreClick(context)),
              ],
            ),
          ),
          SizedBox(
            height: 292,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                scrollCacheExtent: const ScrollCacheExtent.pixels(2000),
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
                itemCount: section.posts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return PostWidget(
                    post: section.posts[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
