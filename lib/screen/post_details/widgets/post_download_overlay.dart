import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/screen/post_details/widgets/post_media_access_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showPostDownloadOverlay(
  BuildContext context, {
  required bool isSeries,
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
    this.movieDownloadBox,
    this.seasons = const [],
  });

  final bool isSeries;
  final MovieDownloadBox? movieDownloadBox;
  final List<Season> seasons;

  @override
  State<PostDownloadOverlay> createState() => _PostDownloadOverlayState();
}

class _PostDownloadOverlayState extends State<PostDownloadOverlay> {
  int? _expandedSeasonIndex = 0;
  final Map<String, int?> _expandedTypeByKey = {};

  @override
  void initState() {
    super.initState();
    if (widget.isSeries) {
      if (widget.seasons.isNotEmpty) {
        _expandedTypeByKey['s0'] = _firstAvailableSeriesTypeIndex(
          widget.seasons.first.items,
        );
      }
    } else {
      _expandedTypeByKey['movie'] = _firstAvailableMovieTypeIndex(
        widget.movieDownloadBox,
      );
    }
  }

  static int? _firstAvailableMovieTypeIndex(MovieDownloadBox? box) {
    if (box == null) return null;
    final types = _movieTypeEntries(box);
    return types.isEmpty ? null : 0;
  }

  static int? _firstAvailableSeriesTypeIndex(SeriesDownloadBox box) {
    final types = _seriesTypeEntries(box);
    return types.isEmpty ? null : 0;
  }

  static List<_TypeSection<MovieInfo>> _movieTypeEntries(MovieDownloadBox box) {
    return [
      if (box.dubbed.isNotEmpty)
        _TypeSection(
          type: MovieType.dubbed,
          title: 'نسخه دوبله فارسی',
          iconAsset: 'assets/img/mic.svg',
          items: box.dubbed,
        ),
      if (box.subtitle.isNotEmpty)
        _TypeSection(
          type: MovieType.subtitle,
          title: 'نسخه زیرنویس چسبیده',
          iconAsset: 'assets/img/subtitle.svg',
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
          iconAsset: 'assets/img/mic.svg',
          items: box.dubbed,
        ),
      if (box.subtitle.isNotEmpty)
        _TypeSection(
          type: MovieType.subtitle,
          title: 'نسخه زیرنویس چسبیده',
          iconAsset: 'assets/img/subtitle.svg',
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

  Future<void> _openLink(String link) async {
    if (!await ensureMediaAccess(context, actionLabel: 'دانلود')) return;
    if (link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 624, maxHeight: maxHeight),
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
    if (box == null) {
      return const _EmptyDownloadMessage();
    }
    final sections = _movieTypeEntries(box);
    if (sections.isEmpty) return const _EmptyDownloadMessage();

    return Column(
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          _AccordionCard(
            title: sections[i].title,
            iconAsset: sections[i].iconAsset,
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
                    onDownload: () => _openLink(sections[i].items[j].link),
                    onCopy: () => _copyLink(sections[i].items[j].link),
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

    return Column(
      children: [
        for (var s = 0; s < widget.seasons.length; s++) ...[
          if (s > 0) const SizedBox(height: 24),
          _AccordionCard(
            title: 'فصل ${widget.seasons[s].name}',
            expanded: _expandedSeasonIndex == s,
            onToggle: () {
              setState(() {
                if (_expandedSeasonIndex == s) {
                  _expandedSeasonIndex = null;
                } else {
                  _expandedSeasonIndex = s;
                  _expandedTypeByKey.putIfAbsent(
                    's$s',
                    () => _firstAvailableSeriesTypeIndex(
                      widget.seasons[s].items,
                    ),
                  );
                }
              });
            },
            child: _buildSeasonTypes(s, widget.seasons[s].items),
          ),
        ],
      ],
    );
  }

  Widget _buildSeasonTypes(int seasonIndex, SeriesDownloadBox box) {
    final sections = _seriesTypeEntries(box);
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
            expanded: _expandedTypeByKey[key] == i,
            onToggle: () {
              setState(() {
                _expandedTypeByKey[key] =
                    _expandedTypeByKey[key] == i ? null : i;
              });
            },
            child: Column(
              children: [
                for (final quality in sections[i].items) ...[
                  _SeriesQualityItem(
                    quality: quality,
                    type: sections[i].type,
                    onDownloadEpisode: _openLink,
                    onCopyAll: () => _copyAllLinks(
                      quality.episodes.map((e) => e.link).toList(),
                    ),
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

class _TypeSection<T> {
  const _TypeSection({
    required this.type,
    required this.title,
    required this.iconAsset,
    required this.items,
  });

  final MovieType type;
  final String title;
  final String iconAsset;
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
  });

  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final String? iconAsset;

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
                            Colors.white.withValues(alpha: 0.85),
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
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String iconAsset;
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
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.85),
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
    required this.onDownload,
    required this.onCopy,
  });

  final MovieInfo info;
  final MovieType type;
  final VoidCallback onDownload;
  final VoidCallback onCopy;

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
          Row(
            children: [
              Expanded(
                child: _PrimaryActionButton(
                  label: 'دانلود',
                  iconAsset: 'assets/img/download.svg',
                  onTap: onDownload,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlineActionButton(
                  label: 'کپی لینک دانلود',
                  onTap: onCopy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeriesQualityItem extends StatelessWidget {
  const _SeriesQualityItem({
    required this.quality,
    required this.type,
    required this.onDownloadEpisode,
    required this.onCopyAll,
  });

  final QualityInfo quality;
  final MovieType type;
  final ValueChanged<String> onDownloadEpisode;
  final VoidCallback onCopyAll;

  @override
  Widget build(BuildContext context) {
    final qualityLabel = quality.encoders.isNotEmpty
        ? '${quality.quality} - ${quality.encoders}'
        : quality.quality;
    final extraTitle = switch (type) {
      MovieType.dubbed => 'دوبله',
      MovieType.subtitle => 'نوع زیرنویس',
      _ => 'جزئیات',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetaLine(label: 'کیفیت', value: qualityLabel),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MetaLine(label: 'حجم', value: quality.size),
                  ),
                  Expanded(
                    child: _MetaLine(
                      label: 'تعداد قسمت ها',
                      value: '${quality.episodes.length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MetaLine(label: 'انکدر', value: quality.encoders),
                  ),
                  Expanded(
                    child: _MetaLine(
                      label: extraTitle,
                      value: quality.subtitleTypes,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            const crossSpacing = 8.0;
            const mainSpacing = 10.0;
            const estimatedButtonHeight = 49.0;
            final itemWidth = (maxWidth - crossSpacing) / 2;
            final childAspectRatio = itemWidth / estimatedButtonHeight;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: mainSpacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: quality.episodes.length,
              itemBuilder: (context, index) {
                final episode = quality.episodes[index];
                return _OutlineActionButton(
                  label: 'قسمت ${index + 1}',
                  iconAsset: 'assets/img/download.svg',
                  onTap: () => onDownloadEpisode(episode.link),
                );
              },
            );
          },
        ),
        const SizedBox(height: 10),
        _PrimaryActionButton(
          label: 'کپی تمامی لینک ها',
          onTap: onCopyAll,
          fullWidth: true,
        ),
      ],
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
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.max,
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

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.label,
    required this.onTap,
    this.iconAsset,
  });

  final String label;
  final VoidCallback onTap;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.48)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
              if (iconAsset != null) ...[
                const SizedBox(width: 8),
                SvgPicture.asset(
                  iconAsset!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.75),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
