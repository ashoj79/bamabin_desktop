import 'package:bamabin_desktop/config/color.dart';
import 'package:flutter/material.dart';

/// Placeholder until the real page is implemented.
class MainPlaceholderPage extends StatelessWidget {
  const MainPlaceholderPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: desktopBgColor,
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: desktopMutedColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
