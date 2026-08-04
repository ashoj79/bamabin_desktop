import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class MainHeader extends StatelessWidget {
  const MainHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: desktopBgColor,
        border: Border(bottom: BorderSide(color: desktopHeaderBorderColor)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => context.go(Routes.main),
                borderRadius: BorderRadius.circular(4),
                child: Text(
                  'بامابین',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: desktopInkColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIconButton(
                    asset: 'assets/img/header_search.svg',
                    onTap: () => context.go(Routes.search),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: TempDb.haveUnreadNotif,
                    builder: (context, haveUnread, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _HeaderIconButton(
                            asset: 'assets/img/header_bell.svg',
                            onTap: () => context.go(Routes.notifications),
                          ),
                          if (haveUnread)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: blueColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: TempDb.isLoggedIn,
                    builder: (context, isLoggedIn, _) {
                      if (!isLoggedIn) {
                        return const _AuthButtons();
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () =>
                                  context.go(Routes.subscription),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: blueColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: 'dana',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('خرید اشتراک'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ProfileAvatar(
                            onTap: () => context.go(Routes.profile),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderNavButton(
                label: 'خانه',
                selected: location == Routes.main,
                onTap: () => context.go(Routes.main),
              ),
              _HeaderNavButton(
                label: 'جستجو',
                selected: location == Routes.search,
                onTap: () => context.go(Routes.search),
              ),
              _HeaderNavButton(
                label: 'دسته‌بندی',
                selected: location == Routes.genresList,
                onTap: () => context.go(Routes.genresList),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderNavButton extends StatelessWidget {
  const _HeaderNavButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        foregroundColor: selected ? desktopInkColor : desktopMutedColor,
        textStyle: const TextStyle(
          fontFamily: 'dana',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 45,
          height: 45,
          child: Center(
            child: SvgPicture.asset(
              asset,
              width: 20,
              height: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthButtons extends StatelessWidget {
  const _AuthButtons();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () => context.go(Routes.auth),
        style: ElevatedButton.styleFrom(
          backgroundColor: blueColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          textStyle: const TextStyle(
            fontFamily: 'dana',
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text('ورود / ثبت‌نام'),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = TempDb.username.isNotEmpty
        ? TempDb.username.characters.first
        : 'ب';
    final avatarUrl = TempDb.avatar;

    Widget fallback() => Text(
          initial,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [desktopAccentDarkColor, blueColor],
            ),
            boxShadow: [
              BoxShadow(
                color: blueColor.withValues(alpha: 0.24),
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Center(child: fallback()),
                  placeholder: (_, _) => Center(child: fallback()),
                )
              : fallback(),
        ),
      ),
    );
  }
}
