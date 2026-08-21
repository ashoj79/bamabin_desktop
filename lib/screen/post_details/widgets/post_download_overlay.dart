import 'dart:async';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_bloc.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_event.dart';
import 'package:bamabin_desktop/screen/download_manager/widgets/download_or_copy_dialog.dart';
import 'package:bamabin_desktop/screen/post_details/widgets/post_media_access_guard.dart';
import 'package:bamabin_desktop/utils/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> showPostDownloadOverlay(
  BuildContext context, {
  required bool isSeries,
  required String title,
  String posterUrl = '',
  MovieDownloadBox? movieDownloadBox,
  List<Season>? seasons,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) {
      return PostDownloadOverlay(
        isSeries: isSeries,
        title: title,
        posterUrl: posterUrl,
        movieDownloadBox: movieDownloadBox,
        seasons: seasons ?? const [],
      );
    },
  );
}

class PostDownloadOverlay extends StatefulWidget {
  const PostDownloadOverlay({
    super.key,
    required this.isSeries,
    required this.title,
    this.posterUrl = '',
    this.movieDownloadBox,
    this.seasons = const [],
  });

  final bool isSeries;
  final String title;
  final String posterUrl;
  final MovieDownloadBox? movieDownloadBox;
  final List<Season> seasons;

  @override
  State<PostDownloadOverlay> createState() => _PostDownloadOverlayState();
}

class _PostDownloadOverlayState extends State<PostDownloadOverlay> {
  int? _expandedSeasonIndex;
  final Map<String, int?> _expandedTypeByKey = {};

  int _seasonIndex = 0;
  String? _selectedQuality;
  bool _filterSubtitle = false;
  bool _filterDubbed = false;

  List<String> get _seasonOptions {
    return [
      'همه‌ی فصل‌ها',
      for (final season in widget.seasons) 'فصل ${season.name}',
    ];
  }

  Iterable<Season> get _seasonsInFilter {
    if (_seasonIndex <= 0) return widget.seasons;
    final index = _seasonIndex - 1;
    if (index < 0 || index >= widget.seasons.length) return widget.seasons;
    return [widget.seasons[index]];
  }

  List<String> get _qualityOptions {
    final qualities = <String>{};
    if (widget.isSeries) {
      for (final season in _seasonsInFilter) {
        for (final quality in _allSeriesQualities(season.items)) {
          if (!_matchesType(qualityTypeOf(season.items, quality))) continue;
          final key = _qualityLabel(quality.mainQuality, quality.quality);
          if (key.isNotEmpty) qualities.add(key);
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

  static int _qualityRank(String value) {
    final digits = RegExp(r'\d+').firstMatch(value)?.group(0);
    return int.tryParse(digits ?? '') ?? 0;
  }

  static String _qualityLabel(String mainQuality, String quality) {
    final main = mainQuality.trim();
    if (main.isNotEmpty) return main;
    return quality.trim();
  }

  static MovieType qualityTypeOf(SeriesDownloadBox box, QualityInfo quality) {
    if (box.dubbed.contains(quality)) return MovieType.dubbed;
    if (box.subtitle.contains(quality)) return MovieType.subtitle;
    if (box.screen.contains(quality)) return MovieType.screen;
    return MovieType.native_;
  }

  static List<QualityInfo> _allSeriesQualities(SeriesDownloadBox box) {
    return [...box.dubbed, ...box.subtitle, ...box.screen, ...box.nativeList];
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

  static List<_TypeSection<MovieInfo>> _movieTypeEntries(MovieDownloadBox box) {
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

  static List<_TypeSection<QualityInfo>> _seriesTypeEntries(
    SeriesDownloadBox box,
  ) {
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
                if (_matchesQuality(item.mainQuality, item.quality))
                  item,
            ],
          ),
    ].where((section) => section.items.isNotEmpty).toList();
  }

  List<QualityInfo> _singleSeriesQuality(List<QualityInfo> items) {
    if (items.isEmpty) return const [];
    final sorted = [...items]..sort((a, b) {
      return _qualityRank(
        _qualityLabel(b.mainQuality, b.quality),
      ).compareTo(_qualityRank(_qualityLabel(a.mainQuality, a.quality)));
    });
    return [sorted.first];
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
            items: _singleSeriesQuality([
              for (final item in section.items)
                if (_matchesQuality(item.mainQuality, item.quality)) item,
            ]),
          ),
    ].where((section) => section.items.isNotEmpty).toList();
  }

  Future<void> _enqueueDownload(
    MovieInfo info, {
    String? seasonName,
    int? episodeNumber,
  }) async {
    if (!await ensureMediaAccess(context, actionLabel: 'دانلود')) return;
    if (info.link.isEmpty) return;

    final parts = <String>[widget.title];
    if (seasonName != null && seasonName.isNotEmpty) {
      parts.add('فصل $seasonName');
    }
    final episodeName = info.name.trim();
    if (episodeName.isNotEmpty) {
      parts.add('قسمت $episodeName');
    } else if (episodeNumber != null) {
      parts.add('قسمت $episodeNumber');
    }
    final quality = info.encoder.isNotEmpty
        ? '${info.quality} - ${info.encoder}'
        : info.quality;

    locator<DownloadManagerBloc>().add(
      DownloadEnqueued(
        url: info.link,
        title: parts.join(' - '),
        posterUrl: widget.posterUrl,
        quality: quality,
        sizeLabel: info.size,
      ),
    );
  }

  Future<void> _copyLink(String link) async {
    if (!await ensureMediaAccess(context, actionLabel: 'دانلود')) return;
    if (link.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لینک کپی شد')),
    );
  }

  Future<void> _copyAllLinks(List<String> links) async {
    if (!await ensureMediaAccess(context, actionLabel: 'دانلود')) return;
    final valid = links.where((e) => e.isNotEmpty).toList();
    if (valid.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: valid.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('همه لینک‌ها کپی شدند')),
    );
  }

  List<QualityInfo> _allQualitiesForType(SeriesDownloadBox box, MovieType type) {
    for (final section in _seriesTypeEntries(box)) {
      if (section.type != type) continue;
      final list = [
        for (final item in section.items)
          if (_matchesQuality(item.mainQuality, item.quality)) item,
      ]..sort((a, b) {
          return _qualityRank(
            _qualityLabel(b.mainQuality, b.quality),
          ).compareTo(
            _qualityRank(_qualityLabel(a.mainQuality, a.quality)),
          );
        });
      return list;
    }
    return const [];
  }

  MovieInfo _enrichEpisode(MovieInfo episode, QualityInfo quality) {
    return MovieInfo(
      name: episode.name,
      link: episode.link,
      quality: episode.quality.isNotEmpty ? episode.quality : quality.quality,
      mainQuality:
          episode.mainQuality.isNotEmpty ? episode.mainQuality : quality.mainQuality,
      qualityCode: episode.qualityCode.isNotEmpty
          ? episode.qualityCode
          : quality.qualityCode,
      subtitleTypes: episode.subtitleTypes.isNotEmpty
          ? episode.subtitleTypes
          : quality.subtitleTypes,
      encoder: episode.encoder.isNotEmpty ? episode.encoder : quality.encoders,
      size: episode.size.isNotEmpty ? episode.size : quality.size,
    );
  }

  String _qualityPickLabel(QualityInfo quality, MovieInfo episode) {
    final label = _qualityLabel(quality.mainQuality, quality.quality);
    final encoder = episode.encoder.isNotEmpty
        ? episode.encoder
        : quality.encoders;
    final size = episode.size.isNotEmpty ? episode.size : quality.size;
    final parts = <String>['کیفیت $label'];
    if (encoder.isNotEmpty) parts.add(encoder);
    if (size.isNotEmpty) parts.add(size);
    return parts.join(' · ');
  }

  Future<MovieInfo?> _pickEpisodeQuality({
    required List<QualityInfo> qualities,
    required int episodeNumber,
    required MovieInfo fallbackEpisode,
    required QualityInfo displayQuality,
  }) async {
    if (_selectedQuality != null) {
      return _enrichEpisode(fallbackEpisode, displayQuality);
    }

    final index = episodeNumber - 1;
    final choices = <_MenuChoice<MovieInfo>>[];
    for (final quality in qualities) {
      if (index < 0 || index >= quality.episodes.length) continue;
      final episode = quality.episodes[index];
      choices.add(
        _MenuChoice(
          value: _enrichEpisode(episode, quality),
          label: _qualityPickLabel(quality, episode),
        ),
      );
    }

    if (choices.isEmpty) return null;
    if (choices.length == 1) return choices.first.value;

    return _showDarkMenu<MovieInfo>(items: choices);
  }

  Future<void> _onEpisodeDownload({
    required List<QualityInfo> qualities,
    required MovieInfo episode,
    required int episodeNumber,
    required QualityInfo displayQuality,
    required String seasonName,
  }) async {
    final picked = await _pickEpisodeQuality(
      qualities: qualities,
      episodeNumber: episodeNumber,
      fallbackEpisode: episode,
      displayQuality: displayQuality,
    );
    if (picked == null || !mounted) return;
    await _enqueueDownload(
      picked,
      seasonName: seasonName,
      episodeNumber: episodeNumber,
    );
  }

  Future<void> _onEpisodeCopy({
    required List<QualityInfo> qualities,
    required MovieInfo episode,
    required int episodeNumber,
    required QualityInfo displayQuality,
  }) async {
    final picked = await _pickEpisodeQuality(
      qualities: qualities,
      episodeNumber: episodeNumber,
      fallbackEpisode: episode,
      displayQuality: displayQuality,
    );
    if (picked == null || !mounted) return;
    await _copyLink(picked.link);
  }

  Future<void> _onDownloadOptionSelected(
    MovieInfo info, {
    String? seasonName,
    int? episodeNumber,
  }) async {
    final action = await showDownloadOrCopyDialog(context);
    if (!mounted || action == null) return;

    switch (action) {
      case DownloadOrCopyAction.download:
        await _enqueueDownload(
          info,
          seasonName: seasonName,
          episodeNumber: episodeNumber,
        );
      case DownloadOrCopyAction.copy:
        await _copyLink(info.link);
    }
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

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    final seasonOptions = _seasonOptions;
    final qualityOptions = _qualityOptions;
    final selectedQuality =
        (_selectedQuality != null && qualityOptions.contains(_selectedQuality))
            ? _selectedQuality
            : null;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
          child: Material(
            color: Colors.transparent,
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
                        const Expanded(
                          child: Text(
                            'باکس دانلود',
                            textAlign: TextAlign.start,
                            style: TextStyle(
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
                    child: _DownloadFilters(
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

  Widget _buildMovieBody() {
    final box = widget.movieDownloadBox;
    if (box == null) {
      return const _EmptyDownloadMessage();
    }
    final sections = _filteredMovieSections(box);
    if (sections.isEmpty) return const _EmptyDownloadMessage();

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
                  _MovieQualityItem(
                    info: sections[i].items[j],
                    type: sections[i].type,
                    onSelect: () =>
                        _onDownloadOptionSelected(sections[i].items[j]),
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
    if (widget.seasons.isEmpty) return const _EmptyDownloadMessage();

    final visible = <int>[];
    for (var s = 0; s < widget.seasons.length; s++) {
      if (_seasonIndex > 0 && s != _seasonIndex - 1) continue;
      if (_filteredSeriesSections(widget.seasons[s].items).isNotEmpty) {
        visible.add(s);
      }
    }
    if (visible.isEmpty) return const _EmptyDownloadMessage();

    return Column(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final s = visible[i];
              return _AccordionCard(
                title: 'فصل ${widget.seasons[s].name}',
                expanded: _expandedSeasonIndex == s,
                onToggle: () {
                  setState(() {
                    _expandedSeasonIndex =
                        _expandedSeasonIndex == s ? null : s;
                  });
                },
                child: _buildSeasonTypes(
                  s,
                  widget.seasons[s].name,
                  widget.seasons[s].items,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSeasonTypes(
    int seasonIndex,
    String seasonName,
    SeriesDownloadBox box,
  ) {
    final sections = _filteredSeriesSections(box);
    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'موردی برای دانلود موجود نیست',
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
            child: Column(
              children: [
                for (var q = 0; q < sections[i].items.length; q++) ...[
                  _SeriesQualityItem(
                    quality: sections[i].items[q],
                    onDownloadEpisode: (episode, episodeNumber) {
                      unawaited(
                        _onEpisodeDownload(
                          qualities: _allQualitiesForType(box, sections[i].type),
                          episode: episode,
                          episodeNumber: episodeNumber,
                          displayQuality: sections[i].items[q],
                          seasonName: seasonName,
                        ),
                      );
                    },
                    onCopyEpisode: (episode) {
                      final episodeNumber =
                          sections[i].items[q].episodes.indexOf(episode) + 1;
                      unawaited(
                        _onEpisodeCopy(
                          qualities: _allQualitiesForType(box, sections[i].type),
                          episode: episode,
                          episodeNumber: episodeNumber,
                          displayQuality: sections[i].items[q],
                        ),
                      );
                    },
                    onCopyAll: (quality) {
                      _copyAllLinks(
                        quality.episodes.map((e) => e.link).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ],
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

class _DownloadFilters extends StatelessWidget {
  const _DownloadFilters({
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
                child: _FilterPill(
                  label: seasonLabel,
                  onTap: onSelectSeason,
                  showChevron: true,
                ),
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
              showChevron: true,
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
    this.showChevron = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool showChevron;
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
              if (showChevron) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
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

class _EmptyDownloadMessage extends StatelessWidget {
  const _EmptyDownloadMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          'لینک دانلودی موجود نیست',
          style: TextStyle(fontSize: 15, color: Color(0xFF888888)),
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

class _MovieQualityItem extends StatelessWidget {
  const _MovieQualityItem({
    required this.info,
    required this.type,
    required this.onSelect,
  });

  final MovieInfo info;
  final MovieType type;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final qualityLabel = info.encoder.isNotEmpty
        ? '${info.quality} - ${info.encoder}'
        : info.quality;
    final extraLabel = switch (type) {
      MovieType.dubbed => info.subtitleTypes.isNotEmpty
          ? info.subtitleTypes
          : '',
      MovieType.subtitle => info.subtitleTypes,
      _ => info.subtitleTypes,
    };
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
          _PrimaryActionButton(
            label: 'دانلود',
            iconAsset: 'assets/img/download.svg',
            onTap: onSelect,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _SeriesQualityItem extends StatelessWidget {
  const _SeriesQualityItem({
    required this.quality,
    required this.onDownloadEpisode,
    required this.onCopyEpisode,
    required this.onCopyAll,
  });

  final QualityInfo quality;
  final void Function(MovieInfo episode, int episodeNumber) onDownloadEpisode;
  final ValueChanged<MovieInfo> onCopyEpisode;
  final void Function(QualityInfo quality) onCopyAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 10,
            mainAxisExtent: 49,
          ),
          itemCount: quality.episodes.length,
          itemBuilder: (context, index) {
            final episode = quality.episodes[index];
            return _EpisodeDownloadButton(
              label: episode.episodeLabel(index + 1),
              onDownload: () => onDownloadEpisode(episode, index + 1),
              onCopy: () => onCopyEpisode(episode),
            );
          },
        ),
        const SizedBox(height: 10),
        _PrimaryActionButton(
          label: 'کپی تمامی لینک ها',
          onTap: () => onCopyAll(quality),
          fullWidth: true,
        ),
      ],
    );
  }
}

class _EpisodeDownloadButton extends StatelessWidget {
  const _EpisodeDownloadButton({
    required this.label,
    required this.onDownload,
    required this.onCopy,
  });

  final String label;
  final VoidCallback onDownload;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.48)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDownload,
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.white.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                'assets/img/hero_download.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 4),
              _EpisodeIconButton(
                asset: 'assets/img/copy.svg',
                onTap: onCopy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeIconButton extends StatelessWidget {
  const _EpisodeIconButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 22,
        height: 22,
        child: SvgPicture.asset(asset, width: 20, height: 20),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onTap,
    this.iconAsset,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? iconAsset;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: blueColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconAsset != null) ...[
                SvgPicture.asset(
                  iconAsset!,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
