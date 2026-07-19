class Device {
  final String name;
  final String type;
  final bool isCurrent;

  Device({required this.name, required this.type, required this.isCurrent});

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    name: json['name'] ?? '',
    type: json['type'] ?? '',
    isCurrent: json['is_current'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'is_current': isCurrent,
  };
}
