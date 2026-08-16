import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/home_sections.dart';
import 'package:bamabin_desktop/screen/home/widgets/home_list_section.dart';
import 'package:bamabin_desktop/screen/home/widgets/home_single_section.dart';
import 'package:bamabin_desktop/screen/home/widgets/home_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: desktopBgColor,
      child: ValueListenableBuilder(
        valueListenable: TempDb.homeSections,
        builder: (context, sections, _) {
          final children = <Widget>[];
          for (final section in sections) {
            if (section is SliderSection && section.posts.isNotEmpty) {
              children.add(HomeSlider(posts: section.posts));
            } else if (section is SingleSection && section.post != null) {
              children.add(HomeSingleSection(section: section));
            } else if (section is ListSection) {
              children.add(HomeListSection(section: section));
            }
          }
          children.add(const SizedBox(height: 24));
          return ListView(
            scrollCacheExtent: const ScrollCacheExtent.pixels(1200),
            children: children,
          );
        },
      ),
    );
  }
}
