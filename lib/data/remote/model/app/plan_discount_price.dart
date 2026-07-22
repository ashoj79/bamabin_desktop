class PlanDiscountPrice {
  final int id;
  final int price;

  PlanDiscountPrice({
    required this.id,
    required this.price,
  });

  factory PlanDiscountPrice.fromJson(Map<String, dynamic> json) =>
      PlanDiscountPrice(
        id: _asInt(json['id']),
        price: _asInt(json['price']),
      );

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
