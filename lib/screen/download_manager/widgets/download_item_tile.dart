import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/local/model/download_task.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

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

  Color get _barColor {
    switch (task.status) {
      case DownloadTaskStatus.paused:
        return const Color(0xFFFACC15);
      case DownloadTaskStatus.error:
        return failedColor;
      case DownloadTaskStatus.completed:
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        return blueColor;
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

  IconData get _actionIcon {
    switch (task.status) {
      case DownloadTaskStatus.active:
        return Icons.pause_rounded;
      case DownloadTaskStatus.queued:
        return Icons.pause_rounded;
      case DownloadTaskStatus.completed:
        return Icons.play_arrow_rounded;
      case DownloadTaskStatus.paused:
      case DownloadTaskStatus.error:
        return Icons.download_rounded;
    }
  }

  double get _displayProgress {
    if (task.status == DownloadTaskStatus.completed ||
        task.status == DownloadTaskStatus.error) {
      return 1;
    }
    return task.progress;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Colors.white.withValues(alpha: 0.36)
        : Colors.white.withValues(alpha: 0.06);
    final bg = selected
        ? const Color(0xFF131321)
        : null;

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
            color: bg,
            gradient: bg == null
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF131321).withValues(alpha: 0.75),
                      const Color(0xFF0C0C14),
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              _ActionButton(icon: _actionIcon, onTap: onAction),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _DeleteChip(onTap: onDelete),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            task.title,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 16.1 / 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 4,
                        child: LinearProgressIndicator(
                          value: _displayProgress,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(_barColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _progressText(task),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              height: 20 / 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _statusLabel,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
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
      return '${(mb / 1024).toStringAsFixed(1)}GB';
    }
    if (mb < 1) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)}KB';
    }
    return '${mb.toStringAsFixed(1)}MB';
  }
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
            if (selected || selectionMode)
              Container(color: Colors.black.withValues(alpha: 0.6)),
            if (selected)
              const Center(
                child: Icon(
                  Icons.check_box_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
          ],
        ),
      ),
    );
  }
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
            border: Border.all(color: failedColor.withValues(alpha: 0.55)),
          ),
          child: Text(
            'حذف دانلود',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: failedColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap});

  final IconData icon;
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
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
