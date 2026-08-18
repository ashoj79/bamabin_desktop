import 'dart:io';

import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/model/download_task.dart';
import 'package:bamabin_desktop/screen/player/player_args.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Future<void> playDownloadedTask(
  BuildContext context,
  DownloadTask task,
) async {
  if (task.status != DownloadTaskStatus.completed || task.filePath.isEmpty) {
    return;
  }
  final file = File(task.filePath);
  if (!await file.exists()) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('فایل دانلود شده پیدا نشد')),
    );
    return;
  }
  if (!context.mounted) return;
  context.push(
    Routes.player,
    extra: PlayerArgs.localFile(
      filePath: task.filePath,
      title: task.title,
      posterUrl: task.posterUrl,
    ),
  );
}
