import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/screen/main/widgets/main_header.dart';
import 'package:bamabin_desktop/screen/main/widgets/main_sidebar.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: desktopBgColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: desktopSidebarBorderColor),
              ),
            ),
            child: const MainSidebar(),
          ),
          Expanded(
            child: Column(
              children: [
                const MainHeader(),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
