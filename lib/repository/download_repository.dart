import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bamabin_desktop/data/local/model/download_task.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef DownloadProgressCallback = void Function(DownloadTask task);

class DownloadRepository {
  DownloadRepository() : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(hours: 6),
            sendTimeout: const Duration(seconds: 60),
          ),
        );

  static const maxConcurrent = 2;

  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};
  final Map<String, bool> _pausedIds = {};
  final Map<String, DateTime> _lastProgressEmit = {};
  final Map<String, _SpeedSample> _speedSamples = {};

  List<DownloadTask> _tasks = [];
  File? _queueFile;
  Directory? _downloadsDir;
  bool _initialized = false;

  final _controller = StreamController<List<DownloadTask>>.broadcast();

  Stream<List<DownloadTask>> get tasksStream => _controller.stream;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  Future<void> init() async {
    if (_initialized) return;
    final support = await getApplicationSupportDirectory();
    _queueFile = File(p.join(support.path, 'download_queue.json'));
    _downloadsDir = await _resolveDownloadsDir();
    await _loadQueue();
    // Resume interrupted actives as paused so user can continue.
    _tasks = _tasks.map((t) {
      if (t.status == DownloadTaskStatus.active ||
          t.status == DownloadTaskStatus.queued) {
        return t.copyWith(status: DownloadTaskStatus.paused);
      }
      return t;
    }).toList();
    await _persist();
    _emit();
    _initialized = true;
  }

  Future<Directory> _resolveDownloadsDir() async {
    Directory documents;
    try {
      documents = await getApplicationDocumentsDirectory();
    } catch (_) {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      documents = Directory(p.join(home, 'Documents'));
    }
    final dir = Directory(p.join(documents.path, 'bamabin'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _loadQueue() async {
    final file = _queueFile;
    if (file == null || !await file.exists()) {
      _tasks = [];
      return;
    }
    try {
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      _tasks = list
          .map((e) => DownloadTask.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _tasks = [];
    }
  }

  Future<void> _persist() async {
    final file = _queueFile;
    if (file == null) return;
    final data = jsonEncode(_tasks.map((e) => e.toJson()).toList());
    await file.writeAsString(data);
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_tasks));
    }
  }

  Future<void> _update(DownloadTask task) async {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i < 0) return;
    _tasks[i] = task;
    _emit();
    await _persist();
  }

  String _sanitizeFileName(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _extensionFromUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final ext = p.extension(path).toLowerCase();
    if (ext.isNotEmpty && ext.length <= 5) return ext;
    return '.mp4';
  }

  Future<String> _buildFilePath(DownloadTask task) async {
    final dir = _downloadsDir ?? await _resolveDownloadsDir();
    _downloadsDir = dir;
    final base = _sanitizeFileName(
      [
        task.title,
        if (task.quality.isNotEmpty) task.quality,
      ].join(' - '),
    );
    final ext = _extensionFromUrl(task.url);
    var candidate = p.join(dir.path, '$base$ext');
    if (!await File(candidate).exists()) return candidate;
    // Avoid overwrite for different task ids.
    var n = 1;
    while (await File(p.join(dir.path, '$base ($n)$ext')).exists()) {
      n++;
    }
    return p.join(dir.path, '$base ($n)$ext');
  }

  Future<DownloadTask> enqueue({
    required String url,
    required String title,
    String posterUrl = '',
    String quality = '',
    String sizeLabel = '',
  }) async {
    await init();
    final existing = _tasks.where((t) => t.url == url).toList();
    if (existing.isNotEmpty) {
      final t = existing.first;
      if (t.status == DownloadTaskStatus.completed ||
          t.status == DownloadTaskStatus.active ||
          t.status == DownloadTaskStatus.queued) {
        return t;
      }
      // Re-queue paused/error with same id.
      final revived = t.copyWith(status: DownloadTaskStatus.queued);
      await _update(revived);
      unawaited(_pumpQueue());
      return revived;
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final task = DownloadTask(
      id: id,
      url: url,
      title: title,
      posterUrl: posterUrl,
      quality: quality,
      sizeLabel: sizeLabel,
      status: DownloadTaskStatus.queued,
      createdAt: DateTime.now(),
    );
    final filePath = await _buildFilePath(task);
    final withPath = task.copyWith(filePath: filePath);
    _tasks.insert(0, withPath);
    _emit();
    await _persist();
    unawaited(_pumpQueue());
    return withPath;
  }

  DownloadTask? _find(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> pause(String id) async {
    _pausedIds[id] = true;
    _cancelTokens[id]?.cancel('paused');
    _speedSamples.remove(id);
    final task = _find(id);
    if (task == null) return;
    if (task.status == DownloadTaskStatus.active ||
        task.status == DownloadTaskStatus.queued) {
      await _update(
        task.copyWith(status: DownloadTaskStatus.paused, speedBytesPerSec: 0),
      );
    }
    unawaited(_pumpQueue());
  }

  Future<void> resume(String id) async {
    _pausedIds.remove(id);
    final task = _find(id);
    if (task == null) return;
    if (task.status == DownloadTaskStatus.paused ||
        task.status == DownloadTaskStatus.error) {
      await _update(task.copyWith(status: DownloadTaskStatus.queued));
      unawaited(_pumpQueue());
    }
  }

  Future<void> retry(String id) => resume(id);

  Future<void> revealInFileManager(String filePath) async {
    if (filePath.isEmpty) return;
    final file = File(filePath);
    if (!await file.exists()) return;
    if (Platform.isWindows) {
      await Process.run('explorer.exe', ['/select,', file.path]);
      return;
    }
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', file.path]);
      return;
    }
    final dir = Directory(p.dirname(file.path));
    if (await dir.exists()) {
      await Process.run('xdg-open', [dir.path]);
    }
  }

  Future<void> delete(String id, {bool deleteFile = true}) async {
    _pausedIds[id] = true;
    _cancelTokens[id]?.cancel('deleted');
    _cancelTokens.remove(id);
    final task = _find(id);
    _tasks.removeWhere((t) => t.id == id);
    _emit();
    await _persist();
    if (deleteFile && task != null && task.filePath.isNotEmpty) {
      final file = File(task.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
    _pausedIds.remove(id);
    _lastProgressEmit.remove(id);
    _speedSamples.remove(id);
    unawaited(_pumpQueue());
  }

  Future<void> deleteMany(Iterable<String> ids, {bool deleteFile = true}) async {
    for (final id in ids.toList()) {
      await delete(id, deleteFile: deleteFile);
    }
  }

  Future<void> _pumpQueue() async {
    await init();
    final activeCount =
        _tasks.where((t) => t.status == DownloadTaskStatus.active).length;
    final slots = maxConcurrent - activeCount;
    if (slots <= 0) return;

    final queued = _tasks
        .where((t) => t.status == DownloadTaskStatus.queued)
        .take(slots)
        .toList();
    for (final task in queued) {
      unawaited(_runDownload(task.id));
    }
  }

  Future<void> _runDownload(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index < 0) return;
    var task = _tasks[index];
    if (task.status != DownloadTaskStatus.queued) return;

    _pausedIds.remove(id);
    final cancelToken = CancelToken();
    _cancelTokens[id] = cancelToken;

    task = task.copyWith(status: DownloadTaskStatus.active);
    await _update(task);

    IOSink? sink;
    try {
      final filePath = task.filePath.isNotEmpty
          ? task.filePath
          : await _buildFilePath(task);
      task = task.copyWith(filePath: filePath);

      final file = File(filePath);
      var start = 0;
      if (await file.exists()) {
        start = await file.length();
      }

      final headers = <String, dynamic>{};
      if (start > 0) {
        headers['Range'] = 'bytes=$start-';
      }

      final response = await _dio.get<ResponseBody>(
        task.url,
        cancelToken: cancelToken,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
          followRedirects: true,
          validateStatus: (s) =>
              s != null && (s == 200 || s == 206 || s < 400),
        ),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode != 200 && statusCode != 206) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Unexpected status $statusCode',
        );
      }

      // If server ignored Range and returned 200, overwrite from scratch.
      if (statusCode == 200 && start > 0) {
        start = 0;
      }

      final contentLength = response.headers.value('content-length');
      final chunkTotal = int.tryParse(contentLength ?? '') ?? -1;
      final absoluteTotal = chunkTotal > 0
          ? (statusCode == 206 ? start + chunkTotal : chunkTotal)
          : task.totalBytes;

      sink = file.openWrite(
        mode: start > 0 ? FileMode.append : FileMode.write,
      );

      var received = start;
      _speedSamples[id] = _SpeedSample(
        at: DateTime.now(),
        bytes: received,
        speedBytesPerSec: 0,
      );
      await for (final chunk in response.data!.stream) {
        if (_pausedIds[id] == true || cancelToken.isCancelled) {
          break;
        }
        sink.add(chunk);
        received += chunk.length;
        final i = _tasks.indexWhere((t) => t.id == id);
        if (i < 0) break;

        final now = DateTime.now();
        final speed = _updateSpeed(id, received, now);
        _tasks[i] = _tasks[i].copyWith(
          receivedBytes: received,
          totalBytes: absoluteTotal > 0 ? absoluteTotal : _tasks[i].totalBytes,
          status: DownloadTaskStatus.active,
          filePath: filePath,
          speedBytesPerSec: speed,
        );
        final last = _lastProgressEmit[id];
        if (last == null || now.difference(last).inMilliseconds >= 200) {
          _lastProgressEmit[id] = now;
          _emit();
        }
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (_pausedIds[id] == true || cancelToken.isCancelled) {
        final i = _tasks.indexWhere((t) => t.id == id);
        if (i >= 0) {
          await _update(
            _tasks[i].copyWith(
              status: DownloadTaskStatus.paused,
              speedBytesPerSec: 0,
            ),
          );
        }
        return;
      }

      final len = await file.exists() ? await file.length() : 0;
      await _update(
        task.copyWith(
          status: DownloadTaskStatus.completed,
          receivedBytes: len,
          totalBytes: len > 0 ? len : absoluteTotal,
          filePath: filePath,
          speedBytesPerSec: 0,
        ),
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || _pausedIds[id] == true) {
        final i = _tasks.indexWhere((t) => t.id == id);
        if (i >= 0) {
          await _update(
            _tasks[i].copyWith(
              status: DownloadTaskStatus.paused,
              speedBytesPerSec: 0,
            ),
          );
        }
      } else {
        final i = _tasks.indexWhere((t) => t.id == id);
        if (i >= 0) {
          await _update(
            _tasks[i].copyWith(
              status: DownloadTaskStatus.error,
              speedBytesPerSec: 0,
            ),
          );
        }
      }
    } catch (_) {
      final i = _tasks.indexWhere((t) => t.id == id);
      if (i >= 0) {
        await _update(
          _tasks[i].copyWith(
            status: DownloadTaskStatus.error,
            speedBytesPerSec: 0,
          ),
        );
      }
    } finally {
      try {
        await sink?.flush();
        await sink?.close();
      } catch (_) {}
      _cancelTokens.remove(id);
      _speedSamples.remove(id);
      unawaited(_pumpQueue());
      unawaited(_persist());
    }
  }

  /// EMA of instantaneous rate; samples at least every 400ms.
  double _updateSpeed(String id, int receivedBytes, DateTime now) {
    final sample = _speedSamples[id];
    if (sample == null) {
      _speedSamples[id] = _SpeedSample(
        at: now,
        bytes: receivedBytes,
        speedBytesPerSec: 0,
      );
      return 0;
    }
    final elapsedMs = now.difference(sample.at).inMilliseconds;
    if (elapsedMs < 400) return sample.speedBytesPerSec;

    final deltaBytes = receivedBytes - sample.bytes;
    final instant = deltaBytes / (elapsedMs / 1000.0);
    final smoothed = sample.speedBytesPerSec <= 0
        ? instant
        : (sample.speedBytesPerSec * 0.65 + instant * 0.35);
    _speedSamples[id] = _SpeedSample(
      at: now,
      bytes: receivedBytes,
      speedBytesPerSec: smoothed < 0 ? 0 : smoothed,
    );
    return _speedSamples[id]!.speedBytesPerSec;
  }

  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel('dispose');
    }
    _cancelTokens.clear();
    _controller.close();
  }
}

class _SpeedSample {
  const _SpeedSample({
    required this.at,
    required this.bytes,
    required this.speedBytesPerSec,
  });

  final DateTime at;
  final int bytes;
  final double speedBytesPerSec;
}
