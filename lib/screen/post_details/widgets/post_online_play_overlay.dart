import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:bamabin_desktop/screen/post_details/widgets/post_media_access_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showPostOnlinePlayOverlay(
  BuildContext context, {
  required bool isSeries,
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
    this.movieDownloadBox,
    this.seasons = const [],
  });

  final bool isSeries;
  final MovieDownloadBox? movieDownloadBox;
  final List<Season> seasons;

  @override
  State<PostOnlinePlayOverlay> createState() => _PostOnlinePlayOverlayState();
}

class _PostOnlinePlayOverlayState extends State<PostOnlinePlayOverlay> {
  int? _expandedMovieTypeIndex;

  List<_MovieTypeSection> _movieTypeEntries(MovieDownloadBox box) {
    return [
      if (box.dubbed.isNotEmpty)
        _MovieTypeSection(
          type: MovieType.dubbed,
          title: 'نسخه دوبله فارسی',
          iconAsset: 'assets/img/mic.svg',
          items: box.dubbed,
        ),
      if (box.subtitle.isNotEmpty)
        _MovieTypeSection(
          type: MovieType.subtitle,
          title: 'نسخه زیرنویس چسبیده',
          iconAsset: 'assets/img/subtitle.svg',
          items: box.subtitle,
        ),
      if (box.screen.isNotEmpty)
        _MovieTypeSection(
          type: MovieType.screen,
          title: 'نسخه پرده',
          iconAsset: 'assets/img/cinema_film.svg',
          items: box.screen,
        ),
      if (box.nativeList.isNotEmpty)
        _MovieTypeSection(
          type: MovieType.native_,
          title: 'نسخه اصلی',
          iconAsset: 'assets/img/play.svg',
          items: box.nativeList,
        ),
    ];
  }

  Future<void> _playLink(String link) async {
    if (!await ensureMediaAccess(context, actionLabel: 'پخش آنلاین')) return;
    if (link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  double _seriesSheetWidth(BuildContext context) {
    const columns = 5;
    const gap = 16.0;
    const contentPadding = 48.0; // 24 left + 24 right
    const headerPadding = 64.0; // 32 left + 32 right
    const closeButton = 60.0;
    const headerGap = 12.0;

    final episodes = [
      for (final season in widget.seasons) ..._episodesFromSeason(season),
    ];
    var widestLabel = 'قسمت ۱';
    for (final episode in episodes) {
      final label = 'قسمت ${episode.number}';
      if (label.length > widestLabel.length) widestLabel = label;
    }

    final textScaler = MediaQuery.textScalerOf(context);
    final labelPainter = TextPainter(
      text: TextSpan(
        text: widestLabel,
        style: _EpisodePlayButton.labelStyle,
      ),
      textDirection: TextDirection.rtl,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    // Extra breathing room so labels never clip.
    final cellWidth =
        labelPainter.width + _EpisodePlayButton.horizontalPadding + 32;

    final gridWidth = cellWidth * columns + gap * (columns - 1);
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'انتخاب قسمت',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.rtl,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final headerWidth =
        headerPadding + titlePainter.width + headerGap + closeButton;

    return (gridWidth + contentPadding) > headerWidth
        ? gridWidth + contentPadding
        : headerWidth;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * 0.88;
    const horizontalInset = 24.0;
    final maxSheetWidth = size.width - horizontalInset * 2;
    final sheetWidth = widget.isSeries
        ? _seriesSheetWidth(context).clamp(0.0, maxSheetWidth)
        : 624.0;

    return Material(
      type: MaterialType.transparency,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              horizontalInset,
              0,
              horizontalInset,
              24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxSheetWidth,
                maxHeight: maxHeight,
              ),
              child: Container(
                width: sheetWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
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
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
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
                          _CloseButton(
                            onTap: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          widget.isSeries ? 24 : 32,
                          0,
                          widget.isSeries ? 24 : 32,
                          32,
                        ),
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
      ),
    );
  }

  Widget _buildMovieBody() {
    final box = widget.movieDownloadBox;
    if (box == null) {
      return const _EmptyPlayMessage();
    }
    final sections = _movieTypeEntries(box);
    if (sections.isEmpty) return const _EmptyPlayMessage();

    return Column(
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          _AccordionCard(
            title: sections[i].title,
            iconAsset: sections[i].iconAsset,
            expanded: _expandedMovieTypeIndex == i,
            onToggle: () {
              setState(() {
                _expandedMovieTypeIndex =
                    _expandedMovieTypeIndex == i ? null : i;
              });
            },
            child: Column(
              children: [
                for (var j = 0; j < sections[i].items.length; j++) ...[
                  if (j > 0) const SizedBox(height: 8),
                  _MoviePlayQualityItem(
                    info: sections[i].items[j],
                    type: sections[i].type,
                    onPlay: () => _playLink(sections[i].items[j].link),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var s = 0; s < widget.seasons.length; s++) ...[
          if (s > 0) const SizedBox(height: 16),
          _SeasonEpisodeSection(
            seasonTitle: 'فصل ${widget.seasons[s].name}',
            episodes: _episodesFromSeason(widget.seasons[s]),
            onPlayEpisode: _playLink,
          ),
        ],
      ],
    );
  }
}

List<_EpisodeOption> _episodesFromSeason(Season season) {
  final box = season.items;
  final qualities = [
    ...box.dubbed,
    ...box.subtitle,
    ...box.nativeList,
    ...box.screen,
  ];
  if (qualities.isEmpty) return const [];

  qualities.sort(
    (a, b) => b.episodes.length.compareTo(a.episodes.length),
  );
  final episodes = qualities.first.episodes;
  return [
    for (var i = 0; i < episodes.length; i++)
      _EpisodeOption(number: i + 1, link: episodes[i].link),
  ];
}

class _EpisodeOption {
  const _EpisodeOption({required this.number, required this.link});

  final int number;
  final String link;
}

class _MovieTypeSection {
  const _MovieTypeSection({
    required this.type,
    required this.title,
    required this.iconAsset,
    required this.items,
  });

  final MovieType type;
  final String title;
  final String iconAsset;
  final List<MovieInfo> items;
}

class _SeasonEpisodeSection extends StatelessWidget {
  const _SeasonEpisodeSection({
    required this.seasonTitle,
    required this.episodes,
    required this.onPlayEpisode,
  });

  final String seasonTitle;
  final List<_EpisodeOption> episodes;
  final ValueChanged<String> onPlayEpisode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.36),
              ),
            ),
          ),
          child: Text(
            seasonTitle,
            textAlign: TextAlign.start,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (episodes.isEmpty)
          Text(
            'قسمتی برای پخش موجود نیست',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.48)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: episodes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 63,
            ),
            itemBuilder: (context, index) {
              final episode = episodes[index];
              return _EpisodePlayButton(
                label: 'قسمت ${episode.number}',
                onTap: () => onPlayEpisode(episode.link),
              );
            },
          ),
      ],
    );
  }
}

class _EpisodePlayButton extends StatelessWidget {
  const _EpisodePlayButton({required this.label, required this.onTap});

  static const labelStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const horizontalPadding = 24.0; // 12 * 2

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: labelStyle,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/img/play.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'پخش',
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
        ],
      ),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  SvgPicture.asset(
                    iconAsset,
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: child,
            ),
        ],
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
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          TextSpan(
            text: value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
      shape: const CircleBorder(
        side: BorderSide(color: Color(0x0FFFFFFF)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 60,
          height: 60,
          child: Icon(Icons.close, color: Colors.white, size: 28),
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
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'موردی برای پخش موجود نیست',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF888888)),
      ),
    );
  }
}
