import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainSidebar extends StatelessWidget {
  const MainSidebar({super.key});

  static const _items = <_SidebarItem>[
    _SidebarItem(
      route: Routes.main,
      title: 'خانه',
      icon: Icons.home_outlined,
    ),
    _SidebarItem(
      route: Routes.search,
      title: 'جستجو',
      icon: Icons.search,
    ),
    _SidebarItem(
      route: Routes.subscription,
      title: 'اشتراک',
      icon: Icons.star_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: 64,
      color: desktopSidebarColor,
      padding: const EdgeInsets.only(top: 18, bottom: 22),
      child: Column(
        children: [
          InkWell(
            onTap: () => context.go(Routes.main),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Image.asset(
                'assets/img/small_logo.png',
                width: 34,
                height: 34,
              ),
            ),
          ),
          for (final item in _items)
            _NavIconButton(
              icon: item.icon,
              title: item.title,
              selected: location == item.route,
              onTap: () => context.go(item.route),
            ),
          const Spacer(),
          _NavIconButton(
            icon: Icons.person_outline,
            title: 'حساب',
            selected: location == Routes.profile,
            onTap: () => context.go(Routes.profile),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({
    required this.route,
    required this.title,
    required this.icon,
  });

  final String route;
  final String title;
  final IconData icon;
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Tooltip(
        message: title,
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: selected
              ? blueColor.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                icon,
                size: 20,
                color: selected ? blueColor : desktopNavInactiveColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
