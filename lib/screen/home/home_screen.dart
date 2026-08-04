import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/home_sections.dart';
import 'package:bamabin_desktop/screen/home/widgets/home_list_section.dart';
import 'package:bamabin_desktop/screen/home/widgets/home_single_section.dart';
import 'package:bamabin_desktop/screen/home/widgets/home_slider.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: desktopBgColor,
      child: ValueListenableBuilder(
        valueListenable: TempDb.homeSections,
        builder: (context, sections, _) {
          return ListView(
            children: [
              for (final section in sections) ...[
                if (section is SliderSection && section.posts.isNotEmpty)
                  HomeSlider(posts: section.posts)
                else if (section is SingleSection && section.post != null)
                  HomeSingleSection(section: section)
                else if (section is ListSection)
                  HomeListSection(section: section),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
