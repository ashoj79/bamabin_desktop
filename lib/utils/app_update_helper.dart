import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppUpdateHelper {
  AppUpdateHelper._();

  static const _folderName = 'bamabin_updates';

  static Future<Directory> _updatesDir() async {
    final temp = await getTemporaryDirectory();
    return Directory(p.join(temp.path, _folderName));
  }

  static Future<void> cleanupLeftoverUpdates() async {
    try {
      final dir = await _updatesDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String _defaultFileName() {
    if (Platform.isWindows) return 'bamabin_setup.exe';
    if (Platform.isMacOS) return 'bamabin_update.dmg';
    return 'bamabin_update.AppImage';
  }

  static String _fileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final segment = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : '';
    if (segment.isNotEmpty && segment.contains('.')) {
      return segment;
    }
    return _defaultFileName();
  }

  static Future<File> downloadUpdate({
    required String url,
    required void Function(int downloaded, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await _updatesDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    final file = File(p.join(dir.path, _fileNameFromUrl(url)));
    final dio = Dio();

    final response = await dio.get<ResponseBody>(
      url,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'دانلود با خطا مواجه شد ($statusCode)',
      );
    }

    final contentLength = response.headers.value('content-length');
    final total = int.tryParse(contentLength ?? '') ?? 0;

    final sink = file.openWrite();
    var downloaded = 0;
    var lastReportedKey = -1;

    try {
      await for (final chunk in response.data!.stream) {
        sink.add(chunk);
        downloaded += chunk.length;

        final reportKey = total > 0
            ? ((downloaded * 100) ~/ total).clamp(0, 100)
            : -1 - (downloaded ~/ (256 * 1024));

        if (reportKey != lastReportedKey) {
          lastReportedKey = reportKey;
          onProgress(downloaded, total);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    onProgress(downloaded, total > 0 ? total : downloaded);
    return file;
  }

  static Future<void> openInstallerAndExit(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('فایل نصب پیدا نشد');
    }

    if (Platform.isWindows) {
      await Process.start(
        filePath,
        const [],
        mode: ProcessStartMode.detached,
      );
    } else if (Platform.isMacOS) {
      await Process.start(
        'open',
        [filePath],
        mode: ProcessStartMode.detached,
      );
    } else {
      await Process.start(
        'xdg-open',
        [filePath],
        mode: ProcessStartMode.detached,
      );
    }

    exit(0);
  }
}
