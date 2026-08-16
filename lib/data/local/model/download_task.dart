enum DownloadTaskStatus {
  queued,
  active,
  paused,
  completed,
  error,
}

class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.posterUrl = '',
    this.quality = '',
    this.sizeLabel = '',
    this.filePath = '',
    this.status = DownloadTaskStatus.queued,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0,
    required this.createdAt,
  });

  final String id;
  final String url;
  final String title;
  final String posterUrl;
  final String quality;
  final String sizeLabel;
  final String filePath;
  final DownloadTaskStatus status;
  final int receivedBytes;
  final int totalBytes;

  /// Live transfer rate; not persisted across restarts.
  final double speedBytesPerSec;
  final DateTime createdAt;

  double get progress {
    if (totalBytes <= 0) return 0;
    return (receivedBytes / totalBytes).clamp(0.0, 1.0);
  }

  int get progressPercent => (progress * 100).round();

  bool get isActiveLike =>
      status == DownloadTaskStatus.active || status == DownloadTaskStatus.queued;

  /// Estimated time left based on current speed; null when unknown.
  Duration? get estimatedTimeRemaining {
    if (status != DownloadTaskStatus.active) return null;
    if (speedBytesPerSec <= 0 || totalBytes <= 0) return null;
    final remaining = totalBytes - receivedBytes;
    if (remaining <= 0) return Duration.zero;
    return Duration(seconds: (remaining / speedBytesPerSec).ceil());
  }

  DownloadTask copyWith({
    String? id,
    String? url,
    String? title,
    String? posterUrl,
    String? quality,
    String? sizeLabel,
    String? filePath,
    DownloadTaskStatus? status,
    int? receivedBytes,
    int? totalBytes,
    double? speedBytesPerSec,
    DateTime? createdAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      quality: quality ?? this.quality,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'posterUrl': posterUrl,
        'quality': quality,
        'sizeLabel': sizeLabel,
        'filePath': filePath,
        'status': status.name,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      posterUrl: json['posterUrl'] as String? ?? '',
      quality: json['quality'] as String? ?? '',
      sizeLabel: json['sizeLabel'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      status: DownloadTaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadTaskStatus.queued,
      ),
      receivedBytes: json['receivedBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
