import 'dart:async';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/dialogs.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/user/vip_info.dart';
import 'package:bamabin_desktop/screen/profile/bloc/profile_bloc.dart';
import 'package:bamabin_desktop/utils/di.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class HeaderProfileButton extends StatefulWidget {
  const HeaderProfileButton({super.key});

  @override
  State<HeaderProfileButton> createState() => _HeaderProfileButtonState();
}

class _HeaderProfileButtonState extends State<HeaderProfileButton> {
  final _portalController = OverlayPortalController();
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _keepOpen() {
    _hideTimer?.cancel();
    if (!_portalController.isShowing) {
      _portalController.show();
    }
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted && _portalController.isShowing) {
        _portalController.hide();
      }
    });
  }

  void _hide() {
    _hideTimer?.cancel();
    if (_portalController.isShowing) {
      _portalController.hide();
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFF2B2B2B),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'آیا می‌خواهید از حساب کاربری خود خارج شوید؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text(
                      'خیر',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'بله',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: redColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _logout(context);
  }

  Future<void> _logout(BuildContext context) async {
    final bloc = locator<ProfileBloc>();
    showLoadingDialog(context);
    final resultFuture = bloc.stream.firstWhere(
      (state) => state is ProfileLogoutSuccess || state is ProfileError,
    );
    bloc.add(ProfileLogoutEvent());
    final result = await resultFuture;
    await bloc.close();
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    if (result is ProfileError) {
      showBamabinSnackbar(context, result.message);
      return;
    }
    context.go(Routes.main);
  }

  Widget _buildOverlay(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null || !box.hasSize) {
      return const SizedBox.shrink();
    }

    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    return Positioned(
      left: offset.dx - 8,
      top: offset.dy + box.size.height + 10,
      child: TapRegion(
        onTapOutside: (_) => _hide(),
        child: MouseRegion(
          onEnter: (_) => _keepOpen(),
          onExit: (_) => _scheduleHide(),
          child: _ProfileHoverPanel(
            onNavigate: (route) {
              _hide();
              context.go(route);
            },
            onLogout: () {
              _hide();
              _confirmLogout(context);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (_) => _buildOverlay(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _keepOpen(),
        onExit: (_) => _scheduleHide(),
        child: GestureDetector(
          onTap: () {
            _hide();
            context.go(Routes.profile);
          },
          child: const _HeaderAvatar(size: 32),
        ),
      ),
    );
  }
}

class _ProfileHoverPanel extends StatelessWidget {
  const _ProfileHoverPanel({
    required this.onNavigate,
    required this.onLogout,
  });

  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ValueListenableBuilder<VipInfo>(
        valueListenable: TempDb.vipInfo,
        builder: (context, vip, _) {
          return Container(
            width: 280,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SubscriptionCard(vip: vip, onRenew: () => onNavigate(Routes.subscription)),
                const SizedBox(height: 12),
                _UserRow(isVip: vip.isVip),
                const SizedBox(height: 8),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 4),
                _MenuItem(
                  label: 'حساب کاربری',
                  iconAsset: 'assets/img/player/player_settings_outline.svg',
                  onTap: () => onNavigate(Routes.profile),
                ),
                _MenuItem(
                  label: 'علاقه مندی ها',
                  iconAsset: 'assets/img/sidebar/ic_heart.svg',
                  onTap: () => onNavigate(Routes.watchlist),
                ),
                _MenuItem(
                  label: 'مشاهده های اخیر',
                  iconAsset: 'assets/img/sidebar/ic_eye.svg',
                  onTap: () => onNavigate(Routes.recentlyViewed),
                ),
                _MenuItem(
                  label: 'لیست های من',
                  iconAsset: 'assets/img/sidebar/ic_bookmark.svg',
                  onTap: () => onNavigate(Routes.userLists),
                ),
                _MenuItem(
                  label: 'پشتیبانی',
                  iconAsset: 'assets/img/sidebar/ic_support.svg',
                  onTap: () => onNavigate(Routes.tickets),
                ),
                _MenuItem(
                  label: 'خروج',
                  icon: Icons.logout_rounded,
                  onTap: onLogout,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.vip, required this.onRenew});

  final VipInfo vip;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final message = vip.isVip
        ? '${_toPersianDigits(vip.days)} روز از اشتراک شما باقیمانده است'
        : 'اشتراک فعالی ندارید';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C241F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.6,
              color: vip.isVip ? const Color(0xFF4ADE80) : desktopMutedColor,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: onRenew,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'dana',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(vip.isVip ? 'تمدید اشتراک' : 'خرید اشتراک'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({required this.isVip});

  final bool isVip;

  @override
  Widget build(BuildContext context) {
    final name = TempDb.username.isNotEmpty ? TempDb.username : 'کاربر';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          const _HeaderAvatar(size: 36),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A42),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isVip ? 'فعال' : 'غیرفعال',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.label,
    required this.onTap,
    this.iconAsset,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final String? iconAsset;
  final IconData? icon;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = Colors.white.withValues(alpha: 0.72);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: widget.iconAsset != null
                    ? SvgPicture.asset(
                        widget.iconAsset!,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          iconColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(widget.icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = TempDb.username.isNotEmpty
        ? TempDb.username.characters.first
        : 'ب';
    final avatarUrl = TempDb.avatar;

    Widget fallback() => Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        );

    return Container(
      width: size,
      height: size,
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
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Center(child: fallback()),
              placeholder: (_, _) => Center(child: fallback()),
            )
          : fallback(),
    );
  }
}

String _toPersianDigits(int value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  final source = value.toString();
  final buffer = StringBuffer();
  for (final char in source.characters) {
    final index = english.indexOf(char);
    buffer.write(index >= 0 ? persian[index] : char);
  }
  return buffer.toString();
}
