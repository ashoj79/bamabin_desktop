import 'package:bamabin_desktop/data/local/menu_icon_type.dart';
import 'package:flutter/material.dart';

class MenuItem {
  final MenuIconType type;
  final String title;
  final String? route;
  final IconData? icon;
  final int? defaultId;
  final Color bgColor;
  final Color iconColor;
  final dynamic extra;
  final bool isSpecial;
  final Color? specialAccentColor;
  bool showBadge;

  MenuItem({
    required this.title,
    required IconData defaultIcon,
    this.route,
    this.bgColor = const Color(0xFF282828),
    this.iconColor = Colors.white,
    this.showBadge = false,
    this.extra,
    this.isSpecial = false,
    this.specialAccentColor,
  }) : type = MenuIconType.icon,
       icon = defaultIcon,
       defaultId = null;
}
