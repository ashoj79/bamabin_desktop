import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/local/post_type.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:flutter/material.dart';

class Filters extends StatelessWidget {
  const Filters({
    super.key,
    required this.onGenreChanged,
    required this.onOrderChanged,
    required this.onImdbChanged,
    required this.genre,
    required this.order,
    required this.imdb,
    this.showPostTypes = false,
    this.allowChangeGenre = true,
    this.onPostTypeChanged,
    this.selectedPostType,
  });

  final void Function(int genreId) onGenreChanged;
  final void Function(String order) onOrderChanged;
  final void Function(int imdb) onImdbChanged;
  final ValueChanged<PostType?>? onPostTypeChanged;
  final int genre;
  final int imdb;
  final String order;
  final PostType? selectedPostType;
  final bool showPostTypes;
  final bool allowChangeGenre;

  static const _orders = <String, String>{
    'date': 'جدیدترین',
    'modified': 'به‌روزترین',
    'release': 'سال انتشار',
    'imdb_rate': 'امتیاز IMDb',
    'popular': 'محبوب‌ترین',
  };

  static const _imdbs = <int, String>{
    0: 'همه امتیازها',
    9: 'بالای ۹',
    8: 'بالای ۸',
    7: 'بالای ۷',
    6: 'بالای ۶',
    5: 'بالای ۵',
  };

  String get _genreLabel {
    if (genre == 0) return 'همه ژانرها';
    for (final item in TempDb.genres) {
      if (item.id == genre) return item.name;
    }
    return 'ژانر';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showPostTypes) ...[
          Row(
            children: [
              _TypeChip(
                title: 'همه',
                selected: selectedPostType == null,
                onTap: () => onPostTypeChanged?.call(null),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                title: 'فیلم',
                selected: selectedPostType == PostType.movie,
                onTap: () => onPostTypeChanged?.call(PostType.movie),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                title: 'سریال',
                selected: selectedPostType == PostType.series,
                onTap: () => onPostTypeChanged?.call(PostType.series),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                title: 'انیمیشن',
                selected: selectedPostType == PostType.animation,
                onTap: () => onPostTypeChanged?.call(PostType.animation),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                title: 'انیمه',
                selected: selectedPostType == PostType.anime,
                onTap: () => onPostTypeChanged?.call(PostType.anime),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                label: 'ژانر',
                value: _genreLabel,
                enabled: allowChangeGenre,
                items: [
                  _FilterItem('همه ژانرها', () => onGenreChanged(0)),
                  ...TempDb.genres.map(
                    (g) => _FilterItem(g.name, () => onGenreChanged(g.id)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilterDropdown(
                label: 'مرتب‌سازی',
                value: _orders[order] ?? 'مرتب‌سازی',
                items: [
                  _FilterItem('مرتب‌سازی', () => onOrderChanged('')),
                  ..._orders.entries.map(
                    (e) => _FilterItem(e.value, () => onOrderChanged(e.key)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilterDropdown(
                label: 'امتیاز IMDb',
                value: _imdbs[imdb] ?? 'امتیاز IMDb',
                items: _imdbs.entries
                    .map(
                      (e) => _FilterItem(e.value, () => onImdbChanged(e.key)),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? blueColor : Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? blueColor
                : Colors.white.withValues(alpha: 0.09),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterItem {
  const _FilterItem(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

class _FilterDropdown extends StatefulWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    this.enabled = true,
  });

  final String label;
  final String value;
  final List<_FilterItem> items;
  final bool enabled;

  @override
  State<_FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<_FilterDropdown> {
  final _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final menuWidth = constraints.maxWidth;
        return MenuAnchor(
          controller: _menuController,
          style: MenuStyle(
            backgroundColor: WidgetStateProperty.all(const Color(0xFF1A1A28)),
            minimumSize: WidgetStateProperty.all(Size(menuWidth, 0)),
            maximumSize: WidgetStateProperty.all(Size(menuWidth, 260)),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 8),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          menuChildren: widget.items
              .map(
                (item) => MenuItemButton(
                  style: MenuItemButton.styleFrom(
                    minimumSize: Size(menuWidth, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () {
                    _menuController.close();
                    item.onTap();
                  },
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      item.label,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              )
              .toList(),
          builder: (context, controller, child) {
            return Material(
              color: const Color(0xFF131321).withValues(alpha: 0.75),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: InkWell(
                onTap: widget.enabled
                    ? () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      }
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.enabled) ...[
                        const SizedBox(width: 4),
                        Icon(
                          controller.isOpen
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
