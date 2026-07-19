class VipInfo {
  final bool isVip;
  final int days;
  final int percentage;

  VipInfo({required this.isVip, this.days = 0, this.percentage = 0});

  factory VipInfo.fromJson(Map<String, dynamic> json) => VipInfo(
    isVip: json['have_vip'] ?? false,
    days: json['days'] ?? 0,
    percentage: (json['percentage'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'have_vip': isVip,
    'days': days,
    'percentage': percentage,
  };
}
