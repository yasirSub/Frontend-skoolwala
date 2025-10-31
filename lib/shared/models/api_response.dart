// ignore_for_file: null_check_on_nullable_type_parameter

class ApiResponse<T> {
  final String status;
  final T? data;
  final String message;

  const ApiResponse({required this.status, this.data, required this.message});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status']?.toString() ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message']?.toString() ?? '',
    );
  }

  // Factory for list responses
  factory ApiResponse.fromJsonList(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status']?.toString() ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message']?.toString() ?? '',
    );
  }

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error' || status == 'failed';

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'status': status,
      'data': data != null ? toJsonT(data!) : null,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'ApiResponse(status: $status, message: $message, data: $data)';
  }
}
