import 'dart:ui';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlayerSeasonsAlert {
  PlayerSeasonsAlert._();

  static const Color _scrim = Color(0x0F131321);
  static const Color _panelBg = Color(0xCC131321);
  static const Color _border = Color(0x17FFFFFF);

  static Future<void> show(
    BuildContext context, {
    required List<Season> seasons,
    required int currentSeason,
    required int currentEpisode,
    required MovieType currentType,
    required bool Function(int seasonIndex, int episodeIndex) isEpisodeWatched,
    required void Function(int seasonIndex, int episodeIndex, MovieType type)
        onEpisodeSelected,
  }) async {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _SeasonsModal(
            seasons: seasons,
            currentSeason: currentSeason,
            currentEpisode: currentEpisode,
            currentType: currentType,
            isEpisodeWatched: isEpisodeWatched,
            onEpisodeSelected: onEpisodeSelected,
          ),
        );
      },
    );
  }
}

class _TypeSection {
  const _TypeSection({
    required this.type,
    required this.title,
    required this.iconAsset,
    required this.iconColor,
    required this.items,
  });

  final MovieType type;
  final String title;
  final String iconAsset;
  final Color? iconColor;
  final List<QualityInfo> items;
}

class _SeasonsModal extends StatefulWidget {
  const _SeasonsModal({
    required this.seasons,
    required this.currentSeason,
    required this.currentEpisode,
    required this.currentType,
    required this.isEpisodeWatched,
    required this.onEpisodeSelected,
  });

  final List<Season> seasons;
  final int currentSeason;
  final int currentEpisode;
  final MovieType currentType;
  final bool Function(int seasonIndex, int episodeIndex) isEpisodeWatched;
  final void Function(int seasonIndex, int episodeIndex, MovieType type)
      onEpisodeSelected;

  @override
  State<_SeasonsModal> createState() => _SeasonsModalState();
}

class _SeasonsModalState extends State<_SeasonsModal> {
  int _seasonFilterIndex = 0;
  int? _expandedSeasonIndex;
  final Map<String, int?> _expandedTypeByKey = {};
  String? _selectedQuality;
  bool _filterSubtitle = false;
  bool _filterDubbed = false;

  @override
  void initState() {
    super.initState();
    _expandedSeasonIndex = widget.currentSeason;
    if (widget.seasons.isNotEmpty) {
      final types = _typeEntries(widget.seasons[widget.currentSeason.clamp(
        0,
        widget.seasons.length - 1,
      )].items);
      final typeIndex = types.indexWhere((e) => e.type == widget.currentType);
      _expandedTypeByKey['s${widget.currentSeason}'] =
          typeIndex >= 0 ? typeIndex : (types.isEmpty ? null : 0);
    }
  }

  List<String> get _seasonOptions => [
        'همه لینک ها',
        for (final season in widget.seasons) 'فصل ${season.name}',
      ];

  Iterable<int> get _visibleSeasonIndexes {
    if (_seasonFilterIndex <= 0) {
      return [
        for (var i = 0; i < widget.seasons.length; i++)
          if (_filteredTypeSections(widget.seasons[i].items).isNotEmpty) i,
      ];
    }
    final index = _seasonFilterIndex - 1;
    if (index < 0 || index >= widget.seasons.length) return const [];
    if (_filteredTypeSections(widget.seasons[index].items).isEmpty) {
      return const [];
    }
    return [index];
  }

  static int _qualityRank(String value) {
    final digits = RegExp(r'\d+').firstMatch(value)?.group(0);
    return int.tryParse(digits ?? '') ?? 0;
  }

  static String _qualityLabel(String mainQuality, String quality) {
    final main = mainQuality.trim();
    if (main.isNotEmpty) return main;
    return quality.trim();
  }

  bool _matchesType(MovieType type) {
    final anyFilter = _filterSubtitle || _filterDubbed;
    if (!anyFilter) return true;
    return switch (type) {
      MovieType.subtitle => _filterSubtitle,
      MovieType.dubbed => _filterDubbed,
      MovieType.native_ || MovieType.screen => false,
    };
  }

  bool _matchesQuality(String mainQuality, String quality) {
    if (_selectedQuality == null) return true;
    return _qualityLabel(mainQuality, quality) == _selectedQuality;
  }

  List<QualityInfo> _singleQuality(List<QualityInfo> items) {
    if (items.isEmpty) return const [];
    final sorted = [...items]..sort((a, b) {
        return _qualityRank(
          _qualityLabel(b.mainQuality, b.quality),
        ).compareTo(_qualityRank(_qualityLabel(a.mainQuality, a.quality)));
      });
    return [sorted.first];
  }

  List<_TypeSection> _typeEntries(SeriesDownloadBox box) {
    return [
      if (box.dubbed.isNotEmpty)
        _TypeSection(
          type: MovieType.dubbed,
          title: 'نسخه دوبله فارسی',
          iconAsset: 'assets/img/post_dubbed.svg',
          iconColor: blueColor,
          items: box.dubbed,
        ),
      if (box.subtitle.isNotEmpty)
        _TypeSection(
          type: MovieType.subtitle,
          title: 'نسخه زیرنویس چسبیده',
          iconAsset: 'assets/img/post_subtitle.svg',
          iconColor: blueColor,
          items: box.subtitle,
        ),
      if (box.screen.isNotEmpty)
        _TypeSection(
          type: MovieType.screen,
          title: 'نسخه پرده',
          iconAsset: 'assets/img/cinema_film.svg',
          iconColor: null,
          items: box.screen,
        ),
      if (box.nativeList.isNotEmpty)
        _TypeSection(
          type: MovieType.native_,
          title: 'نسخه اصلی',
          iconAsset: 'assets/img/play.svg',
          iconColor: null,
          items: box.nativeList,
        ),
    ];
  }

  List<_TypeSection> _filteredTypeSections(SeriesDownloadBox box) {
    return [
      for (final section in _typeEntries(box))
        if (_matchesType(section.type))
          _TypeSection(
            type: section.type,
            title: section.title,
            iconAsset: section.iconAsset,
            iconColor: section.iconColor,
            items: _singleQuality([
              for (final item in section.items)
                if (_matchesQuality(item.mainQuality, item.quality)) item,
            ]),
          ),
    ].where((section) => section.items.isNotEmpty).toList();
  }

  List<String> get _qualityOptions {
    final qualities = <String>{};
    final seasons = _seasonFilterIndex <= 0
        ? widget.seasons
        : [widget.seasons[_seasonFilterIndex - 1]];
    for (final season in seasons) {
      for (final section in _typeEntries(season.items)) {
        if (!_matchesType(section.type)) continue;
        for (final item in section.items) {
          final key = _qualityLabel(item.mainQuality, item.quality);
          if (key.isNotEmpty) qualities.add(key);
        }
      }
    }
    final list = qualities.toList()
      ..sort((a, b) => _qualityRank(b).compareTo(_qualityRank(a)));
    return list;
  }

  void _selectSeason(int index) {
    setState(() {
      _seasonFilterIndex = index;
      if (index > 0) {
        final seasonIndex = index - 1;
        _expandedSeasonIndex = seasonIndex;
        _expandedTypeByKey.putIfAbsent(
          's$seasonIndex',
          () => 0,
        );
      }
    });
  }

  void _cycleSeason(int delta) {
    final options = _seasonOptions;
    if (options.length <= 1) return;
    _selectSeason(
      (_seasonFilterIndex + delta + options.length) % options.length,
    );
  }

  Future<void> _pickSeason() async {
    final options = _seasonOptions;
    if (options.length <= 1) return;
    final selected = await _showMenu<int>([
      for (var i = 0; i < options.length; i++) (value: i, label: options[i]),
    ]);
    if (selected == null) return;
    _selectSeason(selected);
  }

  Future<void> _pickQuality(List<String> options) async {
    final selected = await _showMenu<String>([
      (value: '__all__', label: 'همه کیفیت‌ها'),
      for (final quality in options) (value: quality, label: 'کیفیت $quality'),
    ]);
    if (selected == null || !mounted) return;
    setState(() {
      _selectedQuality = selected == '__all__' ? null : selected;
    });
  }

  Future<T?> _showMenu<T>(List<({T value, String label})> items) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: const Color(0xFF16161E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                for (final item in items)
                  ListTile(
                    title: Text(
                      item.label,
                      textAlign: TextAlign.start,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () => Navigator.of(context).pop(item.value),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final seasonOptions = _seasonOptions;
    final qualityOptions = _qualityOptions;
    final selectedQuality =
        (_selectedQuality != null && qualityOptions.contains(_selectedQuality))
            ? _selectedQuality
            : null;
    final visible = _visibleSeasonIndexes.toList();

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const ColoredBox(color: PlayerSeasonsAlert._scrim),
              ),
            ),
          ),
          Center(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 720,
                    maxHeight: MediaQuery.sizeOf(context).height * 0.88,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: PlayerSeasonsAlert._panelBg,
                          borderRadius: BorderRadius.all(Radius.circular(32)),
                          border: Border(
                            top: BorderSide(color: PlayerSeasonsAlert._border),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'انتخاب قسمت',
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFF5EFE6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _CloseButton(
                                    onTap: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      _CircleNavButton(
                                        icon: Icons.chevron_left_rounded,
                                        onTap: () => _cycleSeason(-1),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _FilterPill(
                                          label: seasonOptions[
                                              _seasonFilterIndex.clamp(
                                            0,
                                            seasonOptions.length - 1,
                                          )],
                                          onTap: _pickSeason,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _CircleNavButton(
                                        icon: Icons.chevron_right_rounded,
                                        onTap: () => _cycleSeason(1),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 10,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      _FilterPill(
                                        label: selectedQuality == null
                                            ? 'همه کیفیت‌ها'
                                            : 'کیفیت $selectedQuality',
                                        onTap: () =>
                                            _pickQuality(qualityOptions),
                                        compact: true,
                                      ),
                                      _LabeledToggle(
                                        label: 'زیرنویس فارسی',
                                        value: _filterSubtitle,
                                        onTap: () => setState(
                                          () => _filterSubtitle =
                                              !_filterSubtitle,
                                        ),
                                      ),
                                      _LabeledToggle(
                                        label: 'دوبله فارسی',
                                        value: _filterDubbed,
                                        onTap: () => setState(
                                          () => _filterDubbed = !_filterDubbed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  0,
                                  24,
                                  24,
                                ),
                                children: [
                                  if (visible.isEmpty)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 40),
                                      child: Center(
                                        child: Text(
                                          'قسمتی برای پخش موجود نیست',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    for (var i = 0; i < visible.length; i++) ...[
                                      if (i > 0) const SizedBox(height: 24),
                                      _buildSeasonCard(visible[i]),
                                    ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonCard(int seasonIndex) {
    final season = widget.seasons[seasonIndex];
    final sections = _filteredTypeSections(season.items);
    final expanded = _expandedSeasonIndex == seasonIndex;
    return _AccordionCard(
      title: 'فصل ${season.name}',
      expanded: expanded,
      onToggle: () {
        setState(() {
          if (_expandedSeasonIndex == seasonIndex) {
            _expandedSeasonIndex = null;
          } else {
            _expandedSeasonIndex = seasonIndex;
            _expandedTypeByKey.putIfAbsent(
              's$seasonIndex',
              () => 0,
            );
          }
        });
      },
      child: Column(
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            const SizedBox(height: 8),
            _NestedTypeCard(
              title: sections[i].title,
              iconAsset: sections[i].iconAsset,
              iconColor: sections[i].iconColor,
              expanded: _expandedTypeByKey['s$seasonIndex'] == i,
              onToggle: () {
                setState(() {
                  _expandedTypeByKey['s$seasonIndex'] =
                      _expandedTypeByKey['s$seasonIndex'] == i ? null : i;
                });
              },
              child: _EpisodeGrid(
                episodes: sections[i].items.first.episodes,
                currentSeason: widget.currentSeason,
                currentEpisode: widget.currentEpisode,
                currentType: widget.currentType,
                seasonIndex: seasonIndex,
                type: sections[i].type,
                isEpisodeWatched: widget.isEpisodeWatched,
                onTap: (episodeIndex) {
                  Navigator.of(context).pop();
                  widget.onEpisodeSelected(
                    seasonIndex,
                    episodeIndex,
                    sections[i].type,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EpisodeGrid extends StatelessWidget {
  const _EpisodeGrid({
    required this.episodes,
    required this.currentSeason,
    required this.currentEpisode,
    required this.currentType,
    required this.seasonIndex,
    required this.type,
    required this.isEpisodeWatched,
    required this.onTap,
  });

  final List<MovieInfo> episodes;
  final int currentSeason;
  final int currentEpisode;
  final MovieType currentType;
  final int seasonIndex;
  final MovieType type;
  final bool Function(int seasonIndex, int episodeIndex) isEpisodeWatched;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 10,
        mainAxisExtent: 56,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final selected = seasonIndex == currentSeason &&
            index == currentEpisode &&
            type == currentType;
        return _EpisodePlayButton(
          label: 'قسمت ${index + 1}',
          selected: selected,
          isWatched: isEpisodeWatched(seasonIndex, index),
          onTap: () => onTap(index),
        );
      },
    );
  }
}

class _EpisodePlayButton extends StatelessWidget {
  const _EpisodePlayButton({
    required this.label,
    required this.selected,
    required this.isWatched,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isWatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = Colors.white.withValues(alpha: selected ? 1 : 0.75);
    return Material(
      color: selected ? blueColor : Colors.white.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? blueColor : Colors.white.withValues(alpha: 0.48),
        ),
      ),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (isWatched) ...[
                SvgPicture.asset(
                  'assets/img/baseline_visibility_24.svg',
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    selected ? Colors.white : blueColor,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.18,
                    color: foreground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  'assets/img/player/player_play_duotone.svg',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(54),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.close_rounded,
            size: 22,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleNavButton extends StatelessWidget {
  const _CircleNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.85)),
        ),
      ),
    );
  }
}

class _LabeledToggle extends StatelessWidget {
  const _LabeledToggle({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MiniSwitch(value: value, onTap: onTap),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSwitch extends StatelessWidget {
  const _MiniSwitch({required this.value, required this.onTap});

  final bool value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: 24,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: value ? blueColor : Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: value ? 0.0 : 0.12),
              ),
            ),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
    required this.title,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 22 / 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ChevronButton(expanded: expanded, onTap: onToggle),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            child,
          ],
        ],
      ),
    );
  }
}

class _NestedTypeCard extends StatelessWidget {
  const _NestedTypeCard({
    required this.title,
    required this.iconAsset,
    this.iconColor,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String iconAsset;
  final Color? iconColor;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          InkWell(
            mouseCursor: SystemMouseCursors.click,
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    iconColor ?? Colors.white.withValues(alpha: 0.85),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 22 / 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ChevronButton(expanded: expanded, onTap: onToggle),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            child,
          ],
        ],
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 45,
          height: 45,
          child: Icon(
            expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.chevron_left_rounded,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}
