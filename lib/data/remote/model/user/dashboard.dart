class Dashboard {
  final String specialDomain;
  final String avatar;
  final int vipTime;
  final double vipTimePercentage;
  final String vipEndDate;
  final int requestsCount;
  final int listsCount;
  final int commentsCount;
  final int favoritesCount;
  final int watchingCount;
  final int notWatchedCount;
  final int watchedCount;
  final int devicesCount;

  Dashboard({
    required this.specialDomain,
    required this.avatar,
    required this.vipTime,
    required this.vipTimePercentage,
    required this.vipEndDate,
    required this.requestsCount,
    required this.listsCount,
    required this.commentsCount,
    required this.favoritesCount,
    required this.watchingCount,
    required this.notWatchedCount,
    required this.watchedCount,
    required this.devicesCount,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => Dashboard(
    specialDomain: json['special_domain'] ?? '',
    avatar: json['avatar'] ?? '',
    vipTime: _asInt(json['vip_time']),
    vipTimePercentage: _asDouble(json['vip_time_percentage']),
    vipEndDate: json['vip_end_date'] ?? '',
    requestsCount: _asInt(json['requests_count']),
    listsCount: _asInt(json['lists_count']),
    commentsCount: _asInt(json['comments_count']),
    favoritesCount: _asInt(json['favorites_count']),
    watchingCount: _asInt(json['watching_count']),
    notWatchedCount: _asInt(json['not_watched_count']),
    watchedCount: _asInt(json['watched_count']),
    devicesCount: _asInt(json['devices_count']),
  );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
