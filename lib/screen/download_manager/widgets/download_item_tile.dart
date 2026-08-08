import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/local/model/download_task.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DownloadItemTile extends StatelessWidget {
  const DownloadItemTile({
    super.key,
    required this.task,
    required this.selected,
    required this.selectionMode,
    required this.onDelete,
    required this.onAction,
    required this.onToggleSelect,
  });

  final DownloadTask task;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onDelete;
  final VoidCallback onAction;
  final VoidCallback onToggleSelect;

  static const _pausedBar = Color(0xFFFACC15);
  static const _errorBar = Color(0xFFEF4444);
  static const _deleteFg = Color(0xFFF87171);

  Color get _barColor {
    switch (task.status) {
      case DownloadTaskStatus.paused:
        return _pausedBar;
      case DownloadTaskStatus.error:
        return _errorBar;
      case DownloadTaskStatus.completed:
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        return blueColor;
    }
  }

  Color get _barGlow {
    switch (task.status) {
      case DownloadTaskStatus.paused:
        return const Color(0x80D3CE34);
      case DownloadTaskStatus.error:
        return const Color(0x80D33434);
      case DownloadTaskStatus.completed:
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        return const Color(0x803479D3);
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        return 'درحال دانلود ...';
      case DownloadTaskStatus.paused:
        return 'متوقف شده';
      case DownloadTaskStatus.completed:
        return 'دانلود تکمیل شده';
      case DownloadTaskStatus.error:
        return 'مشکل در دانلود';
    }
  }

  String get _actionAsset {
    switch (task.status) {
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        return 'assets/img/ic_pause.svg';
      case DownloadTaskStatus.completed:
        return 'assets/img/hero_play_circle.svg';
      case DownloadTaskStatus.paused:
      case DownloadTaskStatus.error:
        return 'assets/img/download.svg';
    }
  }

  double get _displayProgress {
    if (task.status == DownloadTaskStatus.completed ||
        task.status == DownloadTaskStatus.error) {
      return 1;
    }
    return task.progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Colors.white.withValues(alpha: 0.36)
        : Colors.white.withValues(alpha: 0.06);
    final selectedBg = selected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selectionMode ? onToggleSelect : null,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 25, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            color: selectedBg ? const Color(0xFF131321) : null,
            gradient: selectedBg
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF131321).withValues(alpha: 0.75),
                      const Color(0xFF0C0C14),
                    ],
                  ),
          ),
          child: Row(
            children: [
              // RTL: first = right → action button
              _ActionButton(asset: _actionAsset, onTap: onAction),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // RTL: title on right, delete on left
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'dana',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 16.1 / 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _DeleteChip(onTap: onDelete),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _GlowProgressBar(
                      progress: _displayProgress,
                      color: _barColor,
                      glow: _barGlow,
                    ),
                    const SizedBox(height: 8),
                    // RTL: status on right, progress text on left
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _statusLabel,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'vazir',
                              fontSize: 14,
                              color: Colors.white,
                              height: 20 / 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _progressText(task),
                            textAlign: TextAlign.left,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'vazir',
                              fontSize: 14,
                              color: Colors.white,
                              height: 20 / 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const _DashedDivider(),
              const SizedBox(width: 16),
              // RTL: last = left → poster
              _Poster(
                url: task.posterUrl,
                selected: selected,
                selectionMode: selectionMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _progressText(DownloadTask task) {
    final pct = task.status == DownloadTaskStatus.completed
        ? 100
        : task.progressPercent;
    final received = _formatBytes(task.receivedBytes);
    final total = task.totalBytes > 0
        ? _formatBytes(task.totalBytes)
        : (task.sizeLabel.isNotEmpty ? task.sizeLabel : '؟');
    return '$pct% ($received از $total)';
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0MB';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) {
      return '${_faDecimal(mb / 1024)}GB';
    }
    if (mb < 1) {
      final kb = bytes / 1024;
      return '${_faDecimal(kb)}KB';
    }
    return '${_faDecimal(mb)}MB';
  }

  /// Figma uses `/` as decimal separator: `1/1MB`, `22/6MB`.
  static String _faDecimal(double value) {
    final fixed = value < 10
        ? value.toStringAsFixed(1)
        : value.toStringAsFixed(1);
    return fixed.replaceAll('.', '/');
  }
}

class _GlowProgressBar extends StatelessWidget {
  const _GlowProgressBar({
    required this.progress,
    required this.color,
    required this.glow,
  });

  final double progress;
  final Color color;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth * progress.clamp(0.0, 1.0);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              // Figma progress fills from the visual left edge.
              if (width > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(9999),
                      boxShadow: [
                        BoxShadow(
                          color: glow,
                          blurRadius: 40,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 110,
      child: CustomPaint(
        painter: _VerticalDashPainter(
          color: Colors.white.withValues(alpha: 0.28),
        ),
      ),
    );
  }
}

class _VerticalDashPainter extends CustomPainter {
  _VerticalDashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const dash = 10.0;
    const gap = 10.0;
    var y = 0.5;
    final x = size.width / 2;
    while (y < size.height) {
      final end = (y + dash).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.url,
    required this.selected,
    required this.selectionMode,
  });

  final String url;
  final bool selected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 110,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(color: appSurface3Color),
              )
            else
              Container(color: appSurface3Color),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                ),
              ),
            ),
            if (selected || selectionMode)
              Container(color: Colors.black.withValues(alpha: 0.6)),
            if (selected)
              const Center(child: _CheckSquare()),
          ],
        ),
      ),
    );
  }
}

class _CheckSquare extends StatelessWidget {
  const _CheckSquare();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(painter: _CheckSquarePainter()),
    );
  }
}

class _CheckSquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.08, size.width * 0.84,
          size.height * 0.84),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, stroke);

    final check = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.72, size.height * 0.34);
    canvas.drawPath(path, check);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeleteChip extends StatelessWidget {
  const _DeleteChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: DownloadItemTile._deleteFg.withValues(alpha: 0.55),
            ),
          ),
          child: const Text(
            'حذف دانلود',
            style: TextStyle(
              fontFamily: 'vazir',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
              color: DownloadItemTile._deleteFg,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.asset, required this.onTap});

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: SvgPicture.asset(
              asset,
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
