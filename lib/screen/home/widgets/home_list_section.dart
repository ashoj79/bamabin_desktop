import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/post_widget.dart';
import 'package:bamabin_desktop/data/remote/model/videos/home_sections.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeListSection extends StatelessWidget {
  const HomeListSection({super.key, required this.section});

  final ListSection section;

  void _onMoreClick(BuildContext context) {
    if (section.taxonomy != null && section.taxonomyId != null) {
      context.push(
        Routes.taxonomyPosts,
        extra: {
          'taxonomy': section.taxonomy,
          'title': section.name,
          'id': int.tryParse(section.taxonomyId!) ?? 0,
        },
      );
      return;
    }

    context.push(
      Routes.postTypeArchive,
      extra: {
        'postTypes': section.postTypes.join(','),
        'title': section.name,
        'broadcastStatus': section.broadcastStatuses.join(','),
        'miniSerial': section.miniSerial,
        'free': section.isFree,
        'dubbed': section.isDubbed,
        'dlboxType': section.dlboxType,
        'orderBy': section.orderBy,
      },
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
                TextButton(
                  onPressed: () => _onMoreClick(context),
                  style: TextButton.styleFrom(
                    foregroundColor: blueColor,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontFamily: 'dana',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('مشاهده همه ←'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 278,
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
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
                itemCount: section.posts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return PostWidget(post: section.posts[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
