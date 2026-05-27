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

  /// True when the server returned a 422 with a `details[]` payload (Joi/Zod
  /// validation errors). Used by screens to surface field-level reasons.
  bool get isValidationError => statusCode == 422 || code == 'VALIDATION_ERROR';

  /// Flattens the structured `details[]` array the backend returns for
  /// validation failures into a human-readable list of field messages. Falls
  /// back to a plain string representation when the payload is shaped
  /// differently. Returns an empty list when no details were attached.
  List<String> get detailMessages {
    final raw = details;
    if (raw == null || raw.isEmpty) return const [];
    final out = <String>[];
    for (final entry in raw) {
      if (entry is Map) {
        final field = (entry['field'] ?? entry['path'] ?? entry['key'])?.toString();
        final msg = (entry['message'] ?? entry['error'] ?? entry['reason'])?.toString();
        if (field != null && msg != null) {
          out.add('$field: $msg');
        } else if (msg != null) {
          out.add(msg);
        } else if (field != null) {
          out.add(field);
        } else {
          out.add(entry.toString());
        }
      } else if (entry != null) {
        out.add(entry.toString());
      }
    }
    return out;
  }

  @override
  String toString() {
    final detail = detailMessages;
    if (detail.isEmpty) return message;
    return '$message (${detail.join('; ')})';
  }
}
