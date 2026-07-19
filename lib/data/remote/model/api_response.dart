class ApiResponse<T> {
  final bool status;
  final String? message;
  final T? data;

  ApiResponse({required this.status, this.message, this.data});

  ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) : status = json['status'] ?? false,
      message = json['message'] ?? '',
      data = json['result'] != null ? fromJsonT(json['result']) : null;
}
