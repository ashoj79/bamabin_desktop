import 'dart:io';

import 'package:bamabin_desktop/data/local/model/download_task.dart';
import 'package:flutter/services.dart';
import 'package:local_notifier/local_notifier.dart';

/// Shows a system tray/OS notification (+ soft beep) when a download finishes.
class DownloadCompletionNotifier {
  DownloadCompletionNotifier._();

  static final DownloadCompletionNotifier instance =
      DownloadCompletionNotifier._();

  var _ready = false;
  final _knownCompletedIds = <String>{};
  var _seeded = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      await localNotifier.setup(
        appName: 'بامابین',
        shortcutPolicy: ShortcutPolicy.requireCreate,
      );
      _ready = true;
    } catch (_) {
      // Notifications are best-effort; downloads must keep working.
      _ready = false;
    }
  }

  /// Call on every task list update. Seeds completed ids on first call so
  /// reopening the app does not re-notify old downloads.
  Future<void> onTasksUpdated(List<DownloadTask> tasks) async {
    final completed = tasks
        .where((t) => t.status == DownloadTaskStatus.completed)
        .toList();

    if (!_seeded) {
      _knownCompletedIds
        ..clear()
        ..addAll(completed.map((t) => t.id));
      _seeded = true;
      return;
    }

    for (final task in completed) {
      if (_knownCompletedIds.contains(task.id)) continue;
      _knownCompletedIds.add(task.id);
      await _notify(task);
    }

    // Drop ids that were deleted from the queue.
    final liveIds = tasks.map((t) => t.id).toSet();
    _knownCompletedIds.removeWhere((id) => !liveIds.contains(id));
  }

  Future<void> _notify(DownloadTask task) async {
    await _playSoftSound();
    if (!_ready) await init();
    if (!_ready) return;

    final quality = task.quality.trim();
    final body = quality.isNotEmpty
        ? '«${task.title}» ($quality) با موفقیت دانلود شد'
        : '«${task.title}» با موفقیت دانلود شد';

    try {
      final notification = LocalNotification(
        identifier: 'download-done-${task.id}',
        title: 'دانلود کامل شد',
        body: body,
      );
      await notification.show();
    } catch (_) {}
  }

  Future<void> _playSoftSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {
      // Fallback soft beep on Windows if SystemSound is unavailable.
      if (Platform.isWindows) {
        try {
          await Process.run(
            'powershell',
            ['-NoProfile', '-Command', '[console]::beep(880,120)'],
            runInShell: false,
          );
        } catch (_) {}
      }
    }
  }
}
