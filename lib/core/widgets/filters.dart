import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/local/post_type.dart';
import 'package:flutter/material.dart';

class Filters extends StatefulWidget {
  final void Function(int genreId) onGenreChanged;
  final void Function(String order) onOrderChanged;
  final void Function(int imdb) onImdbChanged;
  final ValueChanged<PostType>? onPostTypeChanged;

  final int genre, imdb;
  final String order;
  final PostType? selectedPostType;
  final bool showPostTypes, allowChangeGenre;

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

  @override
  State<Filters> createState() => FiltersState();
}

class FiltersState extends State<Filters> {
  final Map<String, String> _orders = {
    'date': 'جدیدترین',
    'modified': 'به روزترین',
    'release': 'سال انتشار',
    'imdb_rate': 'امتیاز IMDB',
    'popular': 'محبوب ترین',
  };

  final Map<String, String> _imdbs = {
    '1': 'همه',
    '9': 'بالای 9',
    '8': 'بالای 8',
    '7': 'بالای 7',
    '6': 'بالای 6',
    '5': 'بالای 5',
  };

  Widget _postTypeChip(String title, PostType type) {
    final isSelected = widget.selectedPostType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onPostTypeChanged?.call(type),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? yellowColor : secondaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? secondaryColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showPostTypes)
          Row(
            children: [
              _postTypeChip('فیلم', PostType.movie),
              const SizedBox(width: 2),
              _postTypeChip('سریال', PostType.series),
              const SizedBox(width: 2),
              _postTypeChip('انیمیشن', PostType.animation),
              const SizedBox(width: 2),
              _postTypeChip('انیمه', PostType.anime),
            ],
          ),
        if (widget.showPostTypes) const SizedBox(height: 2),

        Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                value: widget.genre == 0
                    ? 'ژانر'
                    : TempDb.genres
                          .firstWhere((g) => g.id == widget.genre)
                          .name,
                items: widget.allowChangeGenre
                    ? [
                        _FilterItem('ژانر', () {
                          widget.onGenreChanged(0);
                        }),
                        ...TempDb.genres.map(
                          (g) => _FilterItem(g.name, () {
                            widget.onGenreChanged(g.id);
                          }),
                        ),
                      ]
                    : [],
              ),
            ),
            Expanded(
              child: _FilterDropdown(
                value: _orders[widget.order] ?? 'مرتب سازی',
                items: [
                  _FilterItem('مرتب سازی', () {
                    widget.onOrderChanged('');
                  }),
                  ..._orders.entries.map(
                    (e) => _FilterItem(e.value, () {
                      widget.onOrderChanged(e.key);
                    }),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _FilterDropdown(
                value: _imdbs[widget.imdb.toString()] ?? 'امتیاز IMDB',
                items: [
                  _FilterItem('امتیاز IMDB', () {
                    widget.onImdbChanged(0);
                  }),
                  ..._imdbs.entries.map(
                    (e) => _FilterItem(e.value, () {
                      widget.onImdbChanged(int.parse(e.key));
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterItem {
  final String label;
  final VoidCallback onTap;

  _FilterItem(this.label, this.onTap);
}

class _FilterDropdown extends StatefulWidget {
  final String value;
  final List<_FilterItem> items;

  const _FilterDropdown({required this.value, required this.items});

  @override
  State<_FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<_FilterDropdown> {
  final _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return MenuAnchor(
      controller: _menuController,
      style: MenuStyle(
        fixedSize: WidgetStateProperty.all(Size(size.width / 3, 200)),
      ),
      menuChildren: widget.items
          .map(
            (item) => MenuItemButton(
              onPressed: () {
                _menuController.close();
                item.onTap();
              },
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          )
          .toList(),
      child: GestureDetector(
        onTap: () {
          if (_menuController.isOpen) {
            _menuController.close();
          } else {
            _menuController.open();
          }
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(left: 2),
          color: secondaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.value),
              Icon(
                _menuController.isOpen
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
