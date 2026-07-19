class Plan {
  final int id;
  final String name;
  final int price;
  final int discountPrice;
  final String iconUrl;
  final int days;
  final bool isDefault;

  Plan({
    required this.id,
    required this.name,
    required this.price,
    required this.discountPrice,
    required this.iconUrl,
    required this.days,
    this.isDefault = false,
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    price: json['price'] ?? 0,
    discountPrice: json['discount_price'] ?? 0,
    iconUrl: json['icon_url'] ?? '',
    days: int.parse(json['time'] ?? '0'),
    isDefault: json['is_default'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'discount_price': discountPrice,
    'icon_url': iconUrl,
    'days': days,
    'is_default': isDefault,
  };
}
