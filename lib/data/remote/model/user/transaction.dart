import 'package:flutter/material.dart';

class Transaction {
  final int id;
  final String price;
  final String status;
  final String days;
  final String date;
  final String authority;

  Transaction({
    required this.id,
    required this.price,
    required this.status,
    required this.days,
    required this.date,
    required this.authority,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'] ?? 0,
    price: json['price']?.toString() ?? '',
    status: json['status'] ?? '',
    days: json['days']?.toString() ?? '',
    date: json['created_at'] ?? '',
    authority: json['authority'] ?? '',
  );

  String get statusLabel {
    switch (status) {
      case 'success':
        return 'موفق';
      case 'failed':
        return 'ناموفق';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  String get month => '${int.parse(days) ~/ 30} ماه';

  String get priceText {
    final value = int.tryParse(price) ?? 0;
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
