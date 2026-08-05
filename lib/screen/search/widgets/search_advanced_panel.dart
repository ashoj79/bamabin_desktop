import 'dart:ui';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/screen/search/bloc/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchAdvancedPanel extends StatefulWidget {
  const SearchAdvancedPanel({
    super.key,
    required this.initial,
    required this.onSubmit,
  });

  final SearchFilters initial;
  final ValueChanged<SearchFilters> onSubmit;

  @override
  State<SearchAdvancedPanel> createState() => _SearchAdvancedPanelState();
}

class _SearchAdvancedPanelState extends State<SearchAdvancedPanel> {
  static const _types = <int, String>{
    0: 'همه',
    1: 'فیلم',
    2: 'سریال',
    3: 'انیمیشن',
    4: 'انیمه',
  };

  static const _typeValues = <int, String>{
    0: '',
    1: 'movies',
    2: 'series',
    3: 'animations',
    4: 'anime',
  };

  static const _imdbItems = <int, String>{
    0: 'همه امتیاز ها',
    9: 'بالای 9',
    8: 'بالای 8',
    7: 'بالای 7',
    6: 'بالای 6',
    5: 'بالای 5',
  };

  static const _orders = <String, String>{
    'date': 'جدیدترین ها',
    'modified': 'به‌روزترین',
    'release': 'سال انتشار',
    'imdb_rate': 'امتیاز IMDb',
    'popular': 'محبوب‌ترین',
  };

  late int _typeKey;
  late int _genreId;
  late int _imdb;
  late String _orderBy;
  late int _country;
  late int _language;
  late int _ageRateId;
  late bool _isDubbed;
  late int _yearFrom;
  late int _yearTo;
  late final TextEditingController _actorController;
  late final TextEditingController _directorController;

  Map<int, String> get _genres => {
        0: 'همه',
        ...Map.fromEntries(TempDb.genres.map((e) => MapEntry(e.id, e.name))),
      };

  Map<int, String> get _countries => {
        0: 'همه',
        ...Map.fromEntries(TempDb.contries.map((e) => MapEntry(e.id, e.name))),
      };

  Map<int, String> get _languages => {
        0: 'همه',
        ...Map.fromEntries(TempDb.languages.map((e) => MapEntry(e.id, e.name))),
      };

  Map<int, String> get _ageRates => {
        -1: 'همه',
        ...Map.fromEntries(TempDb.ageRates.map((e) => MapEntry(e.id, e.name))),
      };

  Map<int, String> get _years {
    final now = DateTime.now().year;
    return {
      0: 'همه',
      for (var y = now; y >= 1950; y--) y: '$y',
    };
  }

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _typeKey = _typeValues.entries
        .firstWhere(
          (e) => e.value == f.type,
          orElse: () => const MapEntry(0, ''),
        )
        .key;
    _genreId = f.genreId;
    _imdb = f.imdb;
    _orderBy = f.orderBy.isEmpty ? 'date' : f.orderBy;
    _country = f.country;
    _language = f.language;
    _ageRateId = -1;
    if (f.ageRate.isNotEmpty) {
      for (final e in TempDb.ageRates) {
        if (e.name == f.ageRate || '${e.id}' == f.ageRate) {
          _ageRateId = e.id;
          break;
        }
      }
    }
    _isDubbed = f.isDubbed;
    _yearFrom = f.yearFrom;
    _yearTo = f.yearTo;
    _actorController = TextEditingController(text: f.actor);
    _directorController = TextEditingController(text: f.director);
  }

  @override
  void dispose() {
    _actorController.dispose();
    _directorController.dispose();
    super.dispose();
  }

  void _submit() {
    var ageRate = '';
    if (_ageRateId != -1) {
      for (final e in TempDb.ageRates) {
        if (e.id == _ageRateId) {
          ageRate = e.name;
          break;
        }
      }
    }

    widget.onSubmit(
      SearchFilters(
        type: _typeValues[_typeKey] ?? '',
        genreId: _genreId,
        imdb: _imdb,
        orderBy: _orderBy,
        country: _country,
        language: _language,
        ageRate: ageRate,
        actor: _actorController.text.trim(),
        director: _directorController.text.trim(),
        isDubbed: _isDubbed,
        yearFrom: _yearFrom,
        yearTo: _yearTo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 945,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF131321).withValues(alpha: 0.8),
                  const Color(0xFF131321).withValues(alpha: 0.48),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'جست و جوی پیشرفته',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 24 / 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _FilterSelect(
                        label: 'ژانر فیلم ها',
                        value: _genres[_genreId] ?? 'همه',
                        items: _genres,
                        onSelected: (id) => setState(() => _genreId = id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterSelect(
                        label: 'رده سنی',
                        value: _ageRates[_ageRateId] ?? 'همه',
                        items: _ageRates,
                        onSelected: (id) => setState(() => _ageRateId = id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterSelect(
                        label: 'نوع عنوان',
                        value: _types[_typeKey] ?? 'همه',
                        items: _types,
                        onSelected: (id) => setState(() => _typeKey = id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterSelect(
                        label: 'امتیاز IMDb',
                        value: _imdbItems[_imdb] ?? 'همه امتیاز ها',
                        items: _imdbItems,
                        onSelected: (id) => setState(() => _imdb = id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterSelect(
                        label: 'زبان ها',
                        value: _languages[_language] ?? 'همه',
                        items: _languages,
                        onSelected: (id) => setState(() => _language = id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterSelect(
                        label: 'کشور ها',
                        value: _countries[_country] ?? 'همه',
                        items: _countries,
                        onSelected: (id) => setState(() => _country = id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterTextField(
                        controller: _directorController,
                        hint: 'نام کارگردان',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterTextField(
                        controller: _actorController,
                        hint: 'نام بازیگر',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterSelect(
                        label: 'مرتب سازی نتایج',
                        value: _orders[_orderBy] ?? 'جدیدترین ها',
                        stringItems: _orders,
                        onStringSelected: (key) =>
                            setState(() => _orderBy = key),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _FilterSelect(
                        label: 'از سال',
                        value: _years[_yearFrom] ?? 'همه',
                        items: _years,
                        valueFontSize: 14,
                        valueFontWeight: FontWeight.w500,
                        onSelected: (id) => setState(() => _yearFrom = id),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _FilterSelect(
                        label: 'تا سال',
                        value: _years[_yearTo] ?? 'همه',
                        items: _years,
                        valueFontSize: 14,
                        valueFontWeight: FontWeight.w500,
                        onSelected: (id) => setState(() => _yearTo = id),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _DubbedToggle(
                        value: _isDubbed,
                        onChanged: (v) => setState(() => _isDubbed = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: Material(
                    color: blueColor,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _submit,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: 16,
                          end: 24,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          textDirection: TextDirection.rtl,
                          children: [
                            SvgPicture.asset(
                              'assets/img/search_magnifer.svg',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'جست و جوی پیشرفته',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.18,
                              ),
                            ),
                          ],
                        ),
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

class _FilterSelect extends StatefulWidget {
  const _FilterSelect({
    required this.label,
    required this.value,
    this.items,
    this.stringItems,
    this.onSelected,
    this.onStringSelected,
    this.valueFontSize = 16,
    this.valueFontWeight = FontWeight.w700,
  });

  final String label;
  final String value;
  final Map<int, String>? items;
  final Map<String, String>? stringItems;
  final ValueChanged<int>? onSelected;
  final ValueChanged<String>? onStringSelected;
  final double valueFontSize;
  final FontWeight valueFontWeight;

  @override
  State<_FilterSelect> createState() => _FilterSelectState();
}

class _FilterSelectState extends State<_FilterSelect> {
  final _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final entries = <_MenuEntry>[];
    if (widget.items != null) {
      for (final e in widget.items!.entries) {
        entries.add(
          _MenuEntry(
            label: e.value,
            onTap: () => widget.onSelected?.call(e.key),
          ),
        );
      }
    } else if (widget.stringItems != null) {
      for (final e in widget.stringItems!.entries) {
        entries.add(
          _MenuEntry(
            label: e.value,
            onTap: () => widget.onStringSelected?.call(e.key),
          ),
        );
      }
    }

    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(const Color(0xFF1A1A28)),
        maximumSize: WidgetStateProperty.all(const Size(280, 260)),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 8)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      menuChildren: entries
          .map(
            (item) => MenuItemButton(
              onPressed: () {
                _menuController.close();
                item.onTap();
              },
              child: SizedBox(
                width: 240,
                child: Text(
                  item.label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
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
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 22 / 16,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: -0.18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: widget.valueFontSize,
                        fontWeight: widget.valueFontWeight,
                        height: 22 / 16,
                        color: Colors.white,
                        letterSpacing: -0.18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MenuEntry {
  const _MenuEntry({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}

class _FilterTextField extends StatelessWidget {
  const _FilterTextField({
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          letterSpacing: -0.18,
        ),
        cursorColor: blueColor,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.6),
            letterSpacing: -0.18,
          ),
          filled: true,
          fillColor: const Color(0xFF131321).withValues(alpha: 0.75),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: blueColor.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}

class _DubbedToggle extends StatelessWidget {
  const _DubbedToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF131321).withValues(alpha: 0.75),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 8,
            end: 16,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 24,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeThumbColor: Colors.white,
                    activeTrackColor: blueColor,
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'فقط دوبله',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 22 / 16,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: -0.18,
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
