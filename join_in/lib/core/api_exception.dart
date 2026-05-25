import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;
  final List<dynamic>? details;

  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiException.fromDioException(DioException error) {
    final response = error.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      final errorBlock = data['error'];
      if (errorBlock is Map<String, dynamic>) {
        return ApiException(
          statusCode: response?.statusCode,
          code: (errorBlock['code'] ?? 'UNKNOWN').toString(),
          message: (errorBlock['message'] ?? error.message ?? 'Request failed').toString(),
          details: errorBlock['details'] is List ? errorBlock['details'] as List : null,
        );
      }
      if (data['message'] is String) {
        return ApiException(
          statusCode: response?.statusCode,
          code: (data['code'] ?? 'UNKNOWN').toString(),
          message: data['message'].toString(),
        );
      }
    }

    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Network timeout. Please check your connection.';
        break;
      case DioExceptionType.connectionError:
        message = 'Unable to reach the server. Check your internet.';
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      default:
        message = error.message ?? 'Something went wrong.';
    }

    return ApiException(
      statusCode: response?.statusCode,
      code: response?.statusCode == 401 ? 'UNAUTHORIZED' : 'NETWORK_ERROR',
      message: message,
    );
  }

  @override
  String toString() => 'ApiException($statusCode $code): $message';
}
