import 'package:bamabin_desktop/data/local/menu_icon_type.dart';
import 'package:flutter/material.dart';

class PostInfoItem {
  final String title;
  final String tooltip;
  final MenuIconType iconType;
  final String? archiveTitle;
  final String? taxonomy;
  final int? id;
  final IconData? icon;
  final String? iconPath;

  PostInfoItem({
    required this.title,
    required this.tooltip,
    required this.iconType,
    this.archiveTitle,
    this.taxonomy,
    this.id,
    this.icon,
    this.iconPath,
  });
}