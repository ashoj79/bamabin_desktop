class WatchReport {
  final WatchReportItem time;
  final WatchReportItem series;
  final WatchReportItem movie;
  final WatchReportItem episode;

  WatchReport({
    required this.time,
    required this.series,
    required this.movie,
    required this.episode,
  });

  factory WatchReport.fromJson(Map<String, dynamic> json) => WatchReport(
    time: WatchReportItem.fromJson(json['time'] ?? {}),
    series: WatchReportItem.fromJson(json['series'] ?? {}),
    movie: WatchReportItem.fromJson(json['movie'] ?? {}),
    episode: WatchReportItem.fromJson(json['episode'] ?? {}),
  );
}

class WatchReportItem {
  final int hollywood;
  final int korean;
  final int animation;
  final int other;
  final int total;

  WatchReportItem({
    required this.hollywood,
    required this.korean,
    required this.animation,
    required this.other,
    this.total = 0,
  });

  factory WatchReportItem.fromJson(Map<String, dynamic> json) =>
      WatchReportItem(
        hollywood: json['hollywood'] ?? 0,
        korean: json['korean'] ?? 0,
        animation: json['animation'] ?? 0,
        other: json['other'] ?? 0,
        total: json['total'] ?? 0,
      );
}
