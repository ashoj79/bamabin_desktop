import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class MainSidebar extends StatelessWidget {
  const MainSidebar({super.key, required this.expandT});

  /// 0 = collapsed, 1 = expanded.
  final double expandT;

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
      title: 'علاقه‌مندی‌ها',
      iconAsset: 'assets/img/sidebar/ic_heart.svg',
      route: Routes.watchlist,
    ),
    _SidebarItem(
      title: 'مشاهده‌های اخیر',
      iconAsset: 'assets/img/sidebar/ic_eye.svg',
      route: Routes.recentlyViewed,
    ),
    _SidebarItem(
      title: 'قفسه‌ی بامابین',
      iconAsset: 'assets/img/sidebar/ic_server.svg',
      route: Routes.watchStatusPosts,
    ),
    _SidebarItem(
      title: 'لیست‌های من',
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
      title: 'دانلود‌ها',
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
    Routes.watchlist,
    Routes.recentlyViewed,
    Routes.watchStatusPosts,
    Routes.downloadManager,
    Routes.tickets,
    Routes.notifications,
    Routes.top250Movies,
    Routes.top250Series,
  };

  bool _isSelected(String location, String route) {
    if (route == Routes.main) {
      return location == Routes.main || location == '/';
    }
    if (route == Routes.tickets) {
      return location == Routes.tickets || location == Routes.ticketDetails;
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
    final t = expandT.clamp(0.0, 1.0);
    final horizontalPad = 8 + 24 * t;
    final radius = 32 * t;
    final labelOpacity = ((t - 0.35) / 0.45).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(radius),
        bottomLeft: Radius.circular(radius),
      ),
      child: ColoredBox(
        color: const Color(0xFF0C0C14),
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 16),
          child: Column(
            children: [
              _SidebarLogo(expandT: t),
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
                                labelOpacity: labelOpacity,
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
                      labelOpacity: labelOpacity,
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
  const _SidebarLogo({required this.expandT});

  final double expandT;

  @override
  Widget build(BuildContext context) {
    final openOpacity = ((expandT - 0.4) / 0.4).clamp(0.0, 1.0);
    final markOpacity = (1 - expandT / 0.45).clamp(0.0, 1.0);

    return SizedBox(
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: markOpacity,
            child: Image.asset(
              'assets/img/sidebar/logo_mark.png',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
          ),
          Opacity(
            opacity: openOpacity,
            child: SvgPicture.asset(
              'assets/img/sidebar/logo_open.svg',
              width: 202,
              height: 54,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.labelOpacity,
    required this.selected,
    required this.onTap,
  });

  final _SidebarItem item;
  final double labelOpacity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? blueColor : const Color(0xB3FFFFFF);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        canRequestFocus: false,
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.white.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                _SidebarIcon(asset: item.iconAsset, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: labelOpacity,
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      softWrap: false,
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
                ),
              ],
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
