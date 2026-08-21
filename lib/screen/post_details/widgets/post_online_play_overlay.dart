import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/screen/player/player_screen.dart';
import 'package:bamabin_desktop/screen/post_details/widgets/post_media_access_guard.dart';
import 'package:bamabin_desktop/utils/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

Future<void> showPostOnlinePlayOverlay(
  BuildContext context, {
  required bool isSeries,
  required String title,
  PostDetails? data,
  MovieDownloadBox? movieDownloadBox,
  List<Season>? seasons,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) {
      return PostOnlinePlayOverlay(
        isSeries: isSeries,
        title: title,
        data: data,
        movieDownloadBox: movieDownloadBox,
        seasons: seasons ?? const [],
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class PostOnlinePlayOverlay extends StatefulWidget {
  const PostOnlinePlayOverlay({
    super.key,
    required this.isSeries,
    required this.title,
    this.data,
    this.movieDownloadBox,
    this.seasons = const [],
  });

  final bool isSeries;
  final String title;
  final PostDetails? data;
  final MovieDownloadBox? movieDownloadBox;
  final List<Season> seasons;

  @override
  State<PostOnlinePlayOverlay> createState() => _PostOnlinePlayOverlayState();
}

class _PostOnlinePlayOverlayState extends State<PostOnlinePlayOverlay> {
  int? _expandedSeasonIndex;
  final Map<String, int?> _expandedTypeByKey = {};
  final Set<String> _watchedEpisodeKeys = {};

  int _seasonIndex = 0;
  String? _selectedQuality;
  bool _filterSubtitle = false;
  bool _filterDubbed = false;

  @override
  void initState() {
    super.initState();
    _loadWatchedEpisodes();
  }

  Future<void> _loadWatchedEpisodes() async {
    if (!widget.isSeries) return;
    final id = widget.data?.id;
    if (id == null) return;
    final list = await locator<VideoRepository>().getWatchedEpisodes(id);
    if (!mounted) return;
    setState(() {
      _watchedEpisodeKeys
        ..clear()
        ..addAll(list.map((e) => '${e.season}:${e.episode}'));
    });
  }

  bool _isEpisodeWatched(int seasonIndex, int episodeIndex) {
    return _watchedEpisodeKeys.contains('$seasonIndex:$episodeIndex');
  }

  List<String> get _seasonOptions => [
        'همه‌ی فصل‌ها',
        for (final season in widget.seasons) 'فصل ${season.name}',
      ];

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

  List<_TypeSection<MovieInfo>> _movieTypeEntries(MovieDownloadBox box) {
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
          items: box.screen,
        ),
      if (box.nativeList.isNotEmpty)
        _TypeSection(
          type: MovieType.native_,
          title: 'نسخه اصلی',
          iconAsset: 'assets/img/play.svg',
          items: box.nativeList,
        ),
    ];
  }

  List<_TypeSection<QualityInfo>> _seriesTypeEntries(SeriesDownloadBox box) {
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
          items: box.screen,
        ),
      if (box.nativeList.isNotEmpty)
        _TypeSection(
          type: MovieType.native_,
          title: 'نسخه اصلی',
          iconAsset: 'assets/img/play.svg',
          items: box.nativeList,
        ),
    ];
  }

  List<_TypeSection<MovieInfo>> _filteredMovieSections(MovieDownloadBox box) {
    return [
      for (final section in _movieTypeEntries(box))
        if (_matchesType(section.type))
          _TypeSection(
            type: section.type,
            title: section.title,
            iconAsset: section.iconAsset,
            iconColor: section.iconColor,
            items: [
              for (final item in section.items)
                if (_matchesQuality(item.mainQuality, item.quality)) item,
            ],
          ),
    ].where((section) => section.items.isNotEmpty).toList();
  }

  List<_TypeSection<QualityInfo>> _filteredSeriesSections(
    SeriesDownloadBox box,
  ) {
    return [
      for (final section in _seriesTypeEntries(box))
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
    if (widget.isSeries) {
      final seasons = _seasonIndex <= 0
          ? widget.seasons
          : [widget.seasons[_seasonIndex - 1]];
      for (final season in seasons) {
        for (final section in _seriesTypeEntries(season.items)) {
          if (!_matchesType(section.type)) continue;
          for (final item in section.items) {
            final key = _qualityLabel(item.mainQuality, item.quality);
            if (key.isNotEmpty) qualities.add(key);
          }
        }
      }
    } else {
      final box = widget.movieDownloadBox;
      if (box != null) {
        for (final section in _movieTypeEntries(box)) {
          if (!_matchesType(section.type)) continue;
          for (final info in section.items) {
            final key = _qualityLabel(info.mainQuality, info.quality);
            if (key.isNotEmpty) qualities.add(key);
          }
        }
      }
    }
    final list = qualities.toList()
      ..sort((a, b) => _qualityRank(b).compareTo(_qualityRank(a)));
    return list;
  }

  Future<void> _openPlayer({
    required String link,
    required MovieType type,
    required int season,
    required int episode,
  }) async {
    if (!await ensureMediaAccess(context, actionLabel: 'پخش آنلاین')) return;
    if (!mounted) return;
    if (link.isEmpty) return;
    final data = widget.data;
    if (data == null) return;

    Navigator.of(context).pop();
    context.push(
      Routes.player,
      extra: PlayerArgs(
        data: data,
        type: type,
        season: season,
        episode: episode,
      ),
    );
  }

  void _selectSeason(int index) {
    setState(() {
      _seasonIndex = index;
      if (index > 0) {
        _expandedSeasonIndex = index - 1;
      }
    });
  }

  void _cycleSeason(int delta) {
    final options = _seasonOptions;
    if (options.length <= 1) return;
    _selectSeason((_seasonIndex + delta + options.length) % options.length);
  }

  Future<void> _pickSeason(List<String> options) async {
    if (options.length <= 1) return;
    final selected = await _showDarkMenu<int>(
      items: [
        for (var i = 0; i < options.length; i++)
          _MenuChoice(value: i, label: options[i]),
      ],
    );
    if (selected == null) return;
    _selectSeason(selected);
  }

  Future<void> _pickQuality(List<String> options) async {
    final selected = await _showDarkMenu<String>(
      items: [
        const _MenuChoice(value: '__all__', label: 'همه کیفیت‌ها'),
        for (final quality in options)
          _MenuChoice(value: quality, label: 'کیفیت $quality'),
      ],
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedQuality = selected == '__all__' ? null : selected;
    });
  }

  Future<T?> _showDarkMenu<T>({required List<_MenuChoice<T>> items}) {
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
                    mouseCursor: SystemMouseCursors.click,
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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final seasonOptions = _seasonOptions;
    final qualityOptions = _qualityOptions;
    final selectedQuality =
        (_selectedQuality != null && qualityOptions.contains(_selectedQuality))
            ? _selectedQuality
            : null;

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.09)),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xBF131321), Color(0xFF0C0C14)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.isSeries ? 'انتخاب قسمت' : 'پخش آنلاین',
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF5EFE6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _CloseButton(onTap: () => Navigator.of(context).pop()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _PlayFilters(
                      showSeasonRow: widget.isSeries,
                      seasonLabel: seasonOptions.isEmpty
                          ? 'همه لینک ها'
                          : seasonOptions[_seasonIndex.clamp(
                              0,
                              seasonOptions.length - 1,
                            )],
                      onPreviousSeason: () => _cycleSeason(-1),
                      onNextSeason: () => _cycleSeason(1),
                      onSelectSeason: () => _pickSeason(seasonOptions),
                      qualityLabel: selectedQuality == null
                          ? 'همه کیفیت‌ها'
                          : 'کیفیت $selectedQuality',
                      onSelectQuality: () => _pickQuality(qualityOptions),
                      filterSubtitle: _filterSubtitle,
                      filterDubbed: _filterDubbed,
                      onToggleSubtitle: () {
                        setState(() => _filterSubtitle = !_filterSubtitle);
                      },
                      onToggleDubbed: () {
                        setState(() => _filterDubbed = !_filterDubbed);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: widget.isSeries
                          ? _buildSeriesBody()
                          : _buildMovieBody(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMovieBody() {
    final box = widget.movieDownloadBox;
    if (box == null) return const _EmptyPlayMessage();
    final sections = _filteredMovieSections(box);
    if (sections.isEmpty) return const _EmptyPlayMessage();

    return Column(
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          _AccordionCard(
            title: sections[i].title,
            iconAsset: sections[i].iconAsset,
            iconColor: sections[i].iconColor,
            expanded: _expandedTypeByKey['movie'] == i,
            onToggle: () {
              setState(() {
                _expandedTypeByKey['movie'] =
                    _expandedTypeByKey['movie'] == i ? null : i;
              });
            },
            child: Column(
              children: [
                for (var j = 0; j < sections[i].items.length; j++) ...[
                  if (j > 0) const SizedBox(height: 8),
                  _MoviePlayQualityItem(
                    info: sections[i].items[j],
                    type: sections[i].type,
                    onPlay: () {
                      final info = sections[i].items[j];
                      _openPlayer(
                        link: info.link,
                        type: sections[i].type,
                        season: j,
                        episode: -1,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSeriesBody() {
    if (widget.seasons.isEmpty) return const _EmptyPlayMessage();

    final visible = <int>[];
    for (var s = 0; s < widget.seasons.length; s++) {
      if (_seasonIndex > 0 && s != _seasonIndex - 1) continue;
      if (_filteredSeriesSections(widget.seasons[s].items).isNotEmpty) {
        visible.add(s);
      }
    }
    if (visible.isEmpty) return const _EmptyPlayMessage();

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          _AccordionCard(
            title: 'فصل ${widget.seasons[visible[i]].name}',
            expanded: _expandedSeasonIndex == visible[i],
            onToggle: () {
              final s = visible[i];
              setState(() {
                _expandedSeasonIndex =
                    _expandedSeasonIndex == s ? null : s;
              });
            },
            child: _buildSeasonTypes(visible[i], widget.seasons[visible[i]].items),
          ),
        ],
      ],
    );
  }

  Widget _buildSeasonTypes(int seasonIndex, SeriesDownloadBox box) {
    final sections = _filteredSeriesSections(box);
    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'موردی برای پخش موجود نیست',
          style: TextStyle(color: Color(0xFF888888)),
        ),
      );
    }

    final key = 's$seasonIndex';
    return Column(
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          const SizedBox(height: 8),
          _NestedTypeCard(
            title: sections[i].title,
            iconAsset: sections[i].iconAsset,
            iconColor: sections[i].iconColor,
            expanded: _expandedTypeByKey[key] == i,
            onToggle: () {
              setState(() {
                _expandedTypeByKey[key] =
                    _expandedTypeByKey[key] == i ? null : i;
              });
            },
            child: _EpisodeGrid(
              episodes: sections[i].items.first.episodes,
              seasonIndex: seasonIndex,
              isEpisodeWatched: _isEpisodeWatched,
              onTap: (episodeIndex) {
                final episode = sections[i].items.first.episodes[episodeIndex];
                _openPlayer(
                  link: episode.link,
                  type: sections[i].type,
                  season: seasonIndex,
                  episode: episodeIndex,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _MenuChoice<T> {
  const _MenuChoice({required this.value, required this.label});

  final T value;
  final String label;
}

class _TypeSection<T> {
  const _TypeSection({
    required this.type,
    required this.title,
    required this.iconAsset,
    required this.items,
    this.iconColor,
  });

  final MovieType type;
  final String title;
  final String iconAsset;
  final Color? iconColor;
  final List<T> items;
}

class _PlayFilters extends StatelessWidget {
  const _PlayFilters({
    required this.showSeasonRow,
    required this.seasonLabel,
    required this.onPreviousSeason,
    required this.onNextSeason,
    required this.onSelectSeason,
    required this.qualityLabel,
    required this.onSelectQuality,
    required this.filterSubtitle,
    required this.filterDubbed,
    required this.onToggleSubtitle,
    required this.onToggleDubbed,
  });

  final bool showSeasonRow;
  final String seasonLabel;
  final VoidCallback onPreviousSeason;
  final VoidCallback onNextSeason;
  final VoidCallback onSelectSeason;
  final String qualityLabel;
  final VoidCallback onSelectQuality;
  final bool filterSubtitle;
  final bool filterDubbed;
  final VoidCallback onToggleSubtitle;
  final VoidCallback onToggleDubbed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSeasonRow) ...[
          Row(
            children: [
              _CircleNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPreviousSeason,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FilterPill(label: seasonLabel, onTap: onSelectSeason),
              ),
              const SizedBox(width: 8),
              _CircleNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNextSeason,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _FilterPill(
              label: qualityLabel,
              onTap: onSelectQuality,
              compact: true,
            ),
            _LabeledToggle(
              label: 'زیرنویس فارسی',
              value: filterSubtitle,
              onTap: onToggleSubtitle,
            ),
            _LabeledToggle(
              label: 'دوبله فارسی',
              value: filterDubbed,
              onTap: onToggleDubbed,
            ),
          ],
        ),
      ],
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

class _EpisodeGrid extends StatelessWidget {
  const _EpisodeGrid({
    required this.episodes,
    required this.seasonIndex,
    required this.isEpisodeWatched,
    required this.onTap,
  });

  final List<MovieInfo> episodes;
  final int seasonIndex;
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
        final episode = episodes[index];
        return _EpisodePlayButton(
          label: episode.episodeLabel(index + 1),
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
    required this.isWatched,
    required this.onTap,
  });

  final String label;
  final bool isWatched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.48)),
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
                  colorFilter: ColorFilter.mode(blueColor, BlendMode.srcIn),
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
                    color: Colors.white.withValues(alpha: 0.75),
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

class _MoviePlayQualityItem extends StatelessWidget {
  const _MoviePlayQualityItem({
    required this.info,
    required this.type,
    required this.onPlay,
  });

  final MovieInfo info;
  final MovieType type;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final qualityLabel = info.encoder.isNotEmpty
        ? '${info.quality} - ${info.encoder}'
        : info.quality;
    final extraLabel = info.subtitleTypes;
    final extraTitle = switch (type) {
      MovieType.dubbed => 'دوبله',
      MovieType.subtitle => 'نوع زیرنویس',
      _ => 'جزئیات',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetaLine(label: 'کیفیت', value: qualityLabel),
                const SizedBox(height: 8),
                _MetaLine(label: 'حجم', value: info.size),
                const SizedBox(height: 8),
                _MetaLine(label: 'انکدر', value: info.encoder),
                if (extraLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _MetaLine(label: extraTitle, value: extraLabel),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: blueColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              mouseCursor: SystemMouseCursors.click,
              onTap: onPlay,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'پخش',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    this.iconAsset,
    this.iconColor,
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final String? iconAsset;
  final Color? iconColor;

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
                  child: Row(
                    children: [
                      if (iconAsset != null) ...[
                        SvgPicture.asset(
                          iconAsset!,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            iconColor ?? Colors.white.withValues(alpha: 0.85),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
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
                    ],
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
                : Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: blueColor,
              height: 20 / 14,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 20 / 14,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.start,
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

class _EmptyPlayMessage extends StatelessWidget {
  const _EmptyPlayMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'موردی برای پخش موجود نیست',
          style: TextStyle(fontSize: 15, color: Color(0xFF888888)),
        ),
      ),
    );
  }
}
