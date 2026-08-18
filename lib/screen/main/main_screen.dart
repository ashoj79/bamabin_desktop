import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/screen/main/widgets/main_header.dart';
import 'package:bamabin_desktop/screen/main/widgets/main_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.child});

  final Widget child;

  static const collapsedSidebarWidth = 80.0;
  static const expandedSidebarWidth = 266.0;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _t = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hideHeader =
        GoRouterState.of(context).matchedLocation == Routes.postDetails;

    return Material(
      color: desktopBgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              constraints.maxWidth - MainScreen.collapsedSidebarWidth;

          return AnimatedBuilder(
            animation: _t,
            child: RepaintBoundary(
              child: Column(
                children: [
                  if (!hideHeader) const MainHeader(),
                  Expanded(child: widget.child),
                ],
              ),
            ),
            builder: (context, child) {
              final t = _t.value;
              final sidebarWidth = MainScreen.collapsedSidebarWidth +
                  (MainScreen.expandedSidebarWidth -
                          MainScreen.collapsedSidebarWidth) *
                      t;
              final extra = sidebarWidth - MainScreen.collapsedSidebarWidth;

              return ClipRect(
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      bottom: 0,
                      width: contentWidth,
                      left: -extra,
                      child: SizedBox(width: contentWidth, child: child),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: 0,
                      width: sidebarWidth,
                      child: MouseRegion(
                        onEnter: (_) => _controller.forward(),
                        onExit: (_) => _controller.reverse(),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: desktopSidebarBorderColor,
                              ),
                            ),
                          ),
                          child: MainSidebar(expandT: t),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
