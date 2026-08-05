import 'dart:ui';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Anchored popover menu matching Figma player menus
/// (quality / speed / subtitle / audio).
class PlayerAnchorMenu {
  PlayerAnchorMenu._();

  static const Color _panelBg = Color(0xB2131321); // rgba(19,19,33,0.7)
  static const Color _selectedBg = Color(0x17FFFFFF); // rgba(255,255,255,0.09)
  static const Color _outline = Color(0x17FFFFFF);

  /// Shows a blur popover above [anchorKey]. Returns the selected index, or
  /// `null` if dismissed. When [footerLabel] is set, tapping it returns `-1`.
  static Future<int?> show(
    BuildContext context, {
    required GlobalKey anchorKey,
    required List<String> items,
    required int currentItem,
    String? footerLabel,
    double itemGap = 2,
  }) async {
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final anchorOffset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final anchorSize = box.size;
    final screen = overlay.size;

    return showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return _AnchorMenuOverlay(
          items: items,
          currentItem: currentItem,
          footerLabel: footerLabel,
          itemGap: itemGap,
          anchorOffset: anchorOffset,
          anchorSize: anchorSize,
          screenSize: screen,
          animation: animation,
        );
      },
    );
  }
}

class _AnchorMenuOverlay extends StatelessWidget {
  const _AnchorMenuOverlay({
    required this.items,
    required this.currentItem,
    required this.footerLabel,
    required this.itemGap,
    required this.anchorOffset,
    required this.anchorSize,
    required this.screenSize,
    required this.animation,
  });

  final List<String> items;
  final int currentItem;
  final String? footerLabel;
  final double itemGap;
  final Offset anchorOffset;
  final Size anchorSize;
  final Size screenSize;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    const gapAbove = 8.0;
    const horizontalPad = 8.0;

    final anchorCenterX = anchorOffset.dx + anchorSize.width / 2;
    final alignX = ((anchorCenterX / screenSize.width) * 2 - 1).clamp(
      -1.0,
      1.0,
    );
    final bottom = screenSize.height - anchorOffset.dy + gapAbove;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: horizontalPad,
          right: horizontalPad,
          bottom: bottom,
          child: Align(
            alignment: Alignment(alignX, 1),
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenSize.width - horizontalPad * 2,
                    maxHeight: screenSize.height * 0.55,
                  ),
                  child: _MenuPanel(
                    items: items,
                    currentItem: currentItem,
                    footerLabel: footerLabel,
                    itemGap: itemGap,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.items,
    required this.currentItem,
    required this.footerLabel,
    required this.itemGap,
  });

  final List<String> items;
  final int currentItem;
  final String? footerLabel;
  final double itemGap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: PlayerAnchorMenu._panelBg,
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: IntrinsicWidth(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 140),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) SizedBox(height: itemGap),
                      _MenuItem(
                        label: items[i],
                        selected: i == currentItem,
                        outlined: false,
                        onTap: () => Navigator.of(context).pop(i),
                      ),
                    ],
                    if (footerLabel != null) ...[
                      SizedBox(height: itemGap > 2 ? itemGap : 6),
                      _MenuItem(
                        label: footerLabel!,
                        selected: false,
                        outlined: true,
                        onTap: () => Navigator.of(context).pop(-1),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.selected,
    required this.outlined,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool outlined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(1000),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? PlayerAnchorMenu._selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(1000),
            border: outlined
                ? Border.all(color: PlayerAnchorMenu._outline)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 16 / 18,
                letterSpacing: -0.12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Season/episode picker modal matching Figma node 35:3065.
class PlayerSeasonsAlert {
  PlayerSeasonsAlert._();

  static const Color _scrim = Color(0x0F131321); // rgba(19,19,33,0.06)
  static const Color _panelBg = Color(0xCC131321); // rgba(19,19,33,0.8)
  static const Color _border = Color(0x17FFFFFF);
  static const Color _cellBg = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color _filterBg = Color(0x17FFFFFF);
  static const Color _filterBorder = Color(0x7AFFFFFF); // ~48%
  static const Color _filterText = Color(0xBFFFFFFF); // ~75%
  static const Color _titleGrey = Color(0xFFF5EFE6);

  static Future<void> show(
    BuildContext context, {
    required Map<int, List<SeasonEpisode>> data,
    required int currentSeason,
    required int currentEpisode,
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
            data: data,
            currentSeason: currentSeason,
            currentEpisode: currentEpisode,
            onEpisodeSelected: onEpisodeSelected,
          ),
        );
      },
    );
  }
}

class _SeasonsModal extends StatefulWidget {
  const _SeasonsModal({
    required this.data,
    required this.currentSeason,
    required this.currentEpisode,
    required this.onEpisodeSelected,
  });

  final Map<int, List<SeasonEpisode>> data;
  final int currentSeason;
  final int currentEpisode;
  final void Function(int seasonIndex, int episodeIndex, MovieType type)
  onEpisodeSelected;

  @override
  State<_SeasonsModal> createState() => _SeasonsModalState();
}

class _SeasonsModalState extends State<_SeasonsModal> {
  /// `null` = همه فصل ها
  int? _filterSeasonKey;

  List<int> get _keys {
    final keys = widget.data.keys.toList()..sort();
    return keys;
  }

  String _seasonTitle(int key) {
    const names = [
      'یک',
      'دو',
      'سه',
      'چهار',
      'پنج',
      'شش',
      'هفت',
      'هشت',
      'نه',
      'ده',
    ];
    if (key >= 1 && key <= names.length) {
      return 'فصل ${names[key - 1]}';
    }
    return 'فصل $key';
  }

  Future<void> _pickSeasonFilter() async {
    final keys = _keys;
    final labels = <String>['همه فصل ها', ...keys.map(_seasonTitle)];
    final current = _filterSeasonKey == null
        ? 0
        : keys.indexOf(_filterSeasonKey!) + 1;

    final selected = await showDialog<int>(
      context: context,
      barrierColor: Colors.black38,
      builder: (ctx) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PlayerSeasonsAlert._panelBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PlayerSeasonsAlert._border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < labels.length; i++)
                    ListTile(
                      dense: true,
                      selected: i == current,
                      selectedTileColor: PlayerSeasonsAlert._filterBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        labels[i],
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () => Navigator.of(ctx).pop(i),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;
    setState(() {
      _filterSeasonKey = selected == 0 ? null : keys[selected - 1];
    });
  }

  @override
  Widget build(BuildContext context) {
    final keys = _keys;
    final visibleKeys = _filterSeasonKey == null
        ? keys
        : keys.where((k) => k == _filterSeasonKey).toList();
    final headerSeasonKey = _filterSeasonKey ??
        (keys.contains(widget.currentSeason + 1)
            ? widget.currentSeason + 1
            : keys.isNotEmpty
            ? keys.first
            : 1);

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1158, maxHeight: 860),
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
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'انتخاب قسمت',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: PlayerSeasonsAlert._titleGrey,
                                      height: 16.1 / 24,
                                    ),
                                  ),
                                ),
                                _PlayerDialogIconButton(
                                  asset:
                                      'assets/img/player/player_close_circle.svg',
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _seasonTitle(headerSeasonKey),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                        height: 30 / 24,
                                        letterSpacing: -0.15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _SeasonFilterChip(
                                    label: _filterSeasonKey == null
                                        ? 'همه فصل ها'
                                        : _seasonTitle(_filterSeasonKey!),
                                    onTap: _pickSeasonFilter,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _DashedDivider(),
                            const SizedBox(height: 16),
                            Expanded(
                              child: Scrollbar(
                                child: ListView(
                                  children: [
                                    for (var i = 0;
                                        i < visibleKeys.length;
                                        i++) ...[
                                      if (i > 0) ...[
                                        const SizedBox(height: 24),
                                        Text(
                                          _seasonTitle(visibleKeys[i]),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                            height: 30 / 24,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const _DashedDivider(),
                                        const SizedBox(height: 16),
                                      ],
                                      PlayerSeasonEpisodesGrid(
                                        episodes:
                                            widget.data[visibleKeys[i]]!,
                                        seasonKey: visibleKeys[i],
                                        currentSeason: widget.currentSeason,
                                        currentEpisode:
                                            widget.currentEpisode,
                                        onEpisodeTap: (ei, ep) {
                                          Navigator.of(context).pop();
                                          widget.onEpisodeSelected(
                                            visibleKeys[i] - 1,
                                            ei,
                                            ep.type,
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
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
}

class _SeasonFilterChip extends StatelessWidget {
  const _SeasonFilterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 217,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: PlayerSeasonsAlert._filterBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PlayerSeasonsAlert._filterBorder),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/img/player/player_season_chevron.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: PlayerSeasonsAlert._filterText,
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

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(color: Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 6.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + dash, 0.5), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PlayerDialogIconButton extends StatelessWidget {
  const _PlayerDialogIconButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x17FFFFFF),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0x0FFFFFFF)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 60,
          height: 60,
          child: Center(
            child: SvgPicture.asset(asset, width: 32, height: 32),
          ),
        ),
      ),
    );
  }
}

class PlayerSeasonEpisodesGrid extends StatelessWidget {
  const PlayerSeasonEpisodesGrid({
    super.key,
    required this.episodes,
    required this.seasonKey,
    required this.currentSeason,
    required this.currentEpisode,
    required this.onEpisodeTap,
  });

  final List<SeasonEpisode> episodes;
  final int seasonKey;
  final int currentSeason;
  final int currentEpisode;
  final void Function(int episodeIndex, SeasonEpisode ep) onEpisodeTap;

  static const int _cols = 5;
  static const double _gap = 16;

  @override
  Widget build(BuildContext context) {
    final rowCount = (episodes.length / _cols).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var r = 0; r < rowCount; r++) ...[
          if (r > 0) const SizedBox(height: _gap),
          Row(
            children: [
              for (var c = 0; c < _cols; c++) ...[
                if (c > 0) const SizedBox(width: _gap),
                Expanded(child: _cell(r, c)),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _cell(int r, int c) {
    final ei = r * _cols + c;
    if (ei >= episodes.length) {
      return const SizedBox.shrink();
    }
    final ep = episodes[ei];
    final isSelected = seasonKey - 1 == currentSeason && currentEpisode == ei;
    return PlayerSeasonEpisodeGridCell(
      episode: ep,
      isSelected: isSelected,
      onTap: () => onEpisodeTap(ei, ep),
    );
  }
}

class PlayerSeasonEpisodeGridCell extends StatelessWidget {
  const PlayerSeasonEpisodeGridCell({
    super.key,
    required this.episode,
    required this.isSelected,
    required this.onTap,
  });

  final SeasonEpisode episode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? blueColor : PlayerSeasonsAlert._cellBg,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'قسمت ${episode.episodeName}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Resume playback?" confirmation dialog.
class PlayerResumeAlert {
  PlayerResumeAlert._();

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: const Color(0xFF2B2B2B),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'قبلا در حال تماشای این ویدئو بوده اید. آیا ادامه می دهید؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blueColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'پخش از ادامه',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        'پخش از ابتدا',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: blueColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }
}
