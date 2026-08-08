import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class MainSidebar extends StatefulWidget {
  const MainSidebar({super.key});

  @override
  State<MainSidebar> createState() => _MainSidebarState();
}

class _MainSidebarState extends State<MainSidebar> {
  static const _collapsedWidth = 80.0;
  static const _expandedWidth = 266.0;
  static const _animDuration = Duration(milliseconds: 220);

  static const _navItems = <_SidebarItem>[
    _SidebarItem(
      title: 'خانه',
      iconAsset: 'assets/img/sidebar/ic_home.svg',
      route: Routes.main,
    ),
    _SidebarItem(
      title: 'جستجو',
      iconAsset: 'assets/img/sidebar/ic_search.svg',
      route: Routes.search,
    ),
    _SidebarItem(
      title: 'علاقه مندی ها',
      iconAsset: 'assets/img/sidebar/ic_heart.svg',
      route: Routes.watchlist,
    ),
    _SidebarItem(
      title: 'مشاهده های اخیر',
      iconAsset: 'assets/img/sidebar/ic_eye.svg',
      route: Routes.watchStatusPosts,
    ),
    _SidebarItem(
      title: 'قفسه بامابین',
      iconAsset: 'assets/img/sidebar/ic_server.svg',
      route: Routes.genresList,
    ),
    _SidebarItem(
      title: 'لیست های من',
      iconAsset: 'assets/img/sidebar/ic_bookmark.svg',
      route: Routes.userLists,
    ),
    _SidebarItem(
      title: '۲۵۰ فیلم برتر',
      iconAsset: 'assets/img/sidebar/ic_movies250.svg',
      route: Routes.top250Movies,
    ),
    _SidebarItem(
      title: '۲۵۰ سریال برتر',
      iconAsset: 'assets/img/sidebar/ic_series250.svg',
      route: Routes.top250Series,
    ),
    _SidebarItem(
      title: 'دانلود ها',
      iconAsset: 'assets/img/sidebar/ic_download.svg',
      route: Routes.downloadManager,
    ),
    _SidebarItem(
      title: 'پشتیبانی',
      iconAsset: 'assets/img/sidebar/ic_support.svg',
      route: Routes.tickets,
    ),
  ];

  static const _bottomItems = <_SidebarItem>[
    _SidebarItem(
      title: 'خرید اشتراک',
      iconAsset: 'assets/img/sidebar/ic_stars.svg',
      route: Routes.subscription,
    ),
    _SidebarItem(
      title: 'حساب کاربری',
      iconAsset: 'assets/img/sidebar/ic_user.svg',
      route: Routes.profile,
    ),
  ];

  static const _routable = <String>{
    Routes.main,
    Routes.search,
    Routes.genresList,
    Routes.subscription,
    Routes.profile,
    Routes.watchStatusPosts,
    Routes.downloadManager,
    Routes.notifications,
    Routes.top250Movies,
    Routes.top250Series,
  };

  bool _expanded = false;

  bool _isSelected(String location, String route) {
    if (route == Routes.main) {
      return location == Routes.main || location == '/';
    }
    return location == route || location.startsWith('$route/');
  }

  void _onItemTap(BuildContext context, String route) {
    if (!_routable.contains(route)) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final expanded = _expanded;

    return MouseRegion(
      onEnter: (_) => setState(() => _expanded = true),
      onExit: (_) => setState(() => _expanded = false),
      child: AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeOutCubic,
        width: expanded ? _expandedWidth : _collapsedWidth,
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C14),
          borderRadius: expanded
              ? const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  bottomLeft: Radius.circular(32),
                )
              : BorderRadius.zero,
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 32 : 8,
            vertical: 16,
          ),
          child: Column(
            children: [
              _SidebarLogo(expanded: expanded),
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < _navItems.length; i++) ...[
                              if (i > 0) const SizedBox(height: 16),
                              _SidebarNavItem(
                                item: _navItems[i],
                                expanded: expanded,
                                selected: _isSelected(
                                  location,
                                  _navItems[i].route,
                                ),
                                onTap: () =>
                                    _onItemTap(context, _navItems[i].route),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Column(
                children: [
                  for (var i = 0; i < _bottomItems.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _SidebarNavItem(
                      item: _bottomItems[i],
                      expanded: expanded,
                      selected: _isSelected(location, _bottomItems[i].route),
                      onTap: () => _onItemTap(context, _bottomItems[i].route),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem {
  const _SidebarItem({
    required this.title,
    required this.iconAsset,
    required this.route,
  });

  final String title;
  final String iconAsset;
  final String route;
}

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: expanded
          ? SvgPicture.asset(
              'assets/img/sidebar/logo_open.svg',
              width: 202,
              height: 54,
              fit: BoxFit.contain,
            )
          : Image.asset(
              'assets/img/sidebar/logo_mark.png',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  final _SidebarItem item;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? blueColor : const Color(0xB3FFFFFF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.white.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 30,
            child: expanded
                ? Row(
                    children: [
                      _SidebarIcon(asset: item.iconAsset, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                            height: 1,
                            letterSpacing: -0.18,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: _SidebarIcon(asset: item.iconAsset, color: color),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({required this.asset, required this.color});

  final String asset;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: SvgPicture.asset(
          asset,
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
