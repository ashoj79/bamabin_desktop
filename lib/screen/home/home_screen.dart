import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/videos/home_sections.dart';
import 'package:bamabin_desktop/screen/home/widgets/home_list_section.dart';
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
          final slider = sections.whereType<SliderSection>().firstOrNull;
          final lists = sections.whereType<ListSection>().toList();

          return ListView(
            children: [
              if (slider != null && slider.posts.isNotEmpty)
                HomeSlider(posts: slider.posts),
              for (final section in lists) HomeListSection(section: section),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
