class AuthResponse {
  final String apiKey;
  final bool deviceLimit;

  AuthResponse({required this.apiKey, required this.deviceLimit});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    apiKey: json['api_key'] ?? '',
    deviceLimit: json['device_limit'] ?? false,
  );
}