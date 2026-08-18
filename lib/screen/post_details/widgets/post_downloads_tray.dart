import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/model/download_task.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_bloc.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_event.dart';
import 'package:bamabin_desktop/screen/download_manager/bloc/download_manager_state.dart';
import 'package:bamabin_desktop/screen/download_manager/download_local_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class PostDownloadsTray extends StatelessWidget {
  const PostDownloadsTray({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadManagerBloc, DownloadManagerState>(
      builder: (context, state) {
        final items = [...state.tasks]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final latest = items.take(4).toList();
        if (latest.isEmpty) return const SizedBox.shrink();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(Routes.downloadManager),
            borderRadius: BorderRadius.circular(24),
            hoverColor: Colors.white.withValues(alpha: 0.04),
            child: Container(
              width: 360,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF131321).withValues(alpha: 0.92),
                    const Color(0xFF0C0C14),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'دانلود های من',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'dana',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        tooltip: 'بستن',
                        icon: SvgPicture.asset(
                          'assets/img/close.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...[
                    for (var i = 0; i < latest.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      _TrayRow(task: latest[i]),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrayRow extends StatelessWidget {
  const _TrayRow({required this.task});

  final DownloadTask task;

  Color get _accent {
    switch (task.status) {
      case DownloadTaskStatus.paused:
        return const Color(0xFFFACC15);
      case DownloadTaskStatus.error:
        return const Color(0xFFEF4444);
      case DownloadTaskStatus.completed:
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        return blueColor;
    }
  }

  Color get _wash {
    switch (task.status) {
      case DownloadTaskStatus.paused:
        return const Color(0x33EAB308);
      case DownloadTaskStatus.error:
        return const Color(0x33EF4444);
      case DownloadTaskStatus.completed:
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        return const Color(0x330EA5E9);
    }
  }

  String get _statusText {
    switch (task.status) {
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        return '${task.progressPercent}%';
      case DownloadTaskStatus.paused:
        return 'توقف';
      case DownloadTaskStatus.completed:
        return 'تکمیل';
      case DownloadTaskStatus.error:
        return 'خطا';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DownloadManagerBloc>();
    final progress = task.status == DownloadTaskStatus.completed ||
            task.status == DownloadTaskStatus.error
        ? 1.0
        : task.progress.clamp(0.0, 1.0);

    return Container(
      height: 70,
      padding: const EdgeInsets.fromLTRB(13, 9, 9, 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            const Color(0xFF131321).withValues(alpha: 0.75),
            _wash,
          ],
        ),
      ),
      child: Row(
        children: [
          _TrayAction(
            task: task,
            onPause: () => bloc.add(DownloadPaused(task.id)),
            onResume: () => bloc.add(DownloadResumed(task.id)),
            onRetry: () => bloc.add(DownloadRetried(task.id)),
            onPlay: () => playDownloadedTask(context, task),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'dana',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusText,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'vazir',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: task.posterUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: task.posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          Container(color: appSurface3Color),
                    )
                  : Container(color: appSurface3Color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrayAction extends StatelessWidget {
  const _TrayAction({
    required this.task,
    required this.onPause,
    required this.onResume,
    required this.onRetry,
    required this.onPlay,
  });

  final DownloadTask task;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRetry;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    late final String asset;
    late final String tooltip;
    late final VoidCallback onTap;

    switch (task.status) {
      case DownloadTaskStatus.active:
      case DownloadTaskStatus.queued:
        asset = 'assets/img/download/ic_pause_duotone.svg';
        tooltip = 'توقف دانلود';
        onTap = onPause;
      case DownloadTaskStatus.paused:
        asset = 'assets/img/download/ic_download_duotone.svg';
        tooltip = 'ادامه دانلود';
        onTap = onResume;
      case DownloadTaskStatus.error:
        asset = 'assets/img/download/ic_download_duotone.svg';
        tooltip = 'تلاش مجدد';
        onTap = onRetry;
      case DownloadTaskStatus.completed:
        asset = 'assets/img/download/ic_play_circle_duotone.svg';
        tooltip = 'پخش در پلیر برنامه';
        onTap = onPlay;
    }

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: SvgPicture.asset(asset, width: 18, height: 18),
            ),
          ),
        ),
      ),
    );
  }
}
