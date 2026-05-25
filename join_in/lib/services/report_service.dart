import '../core/api_client.dart';

class ReportService {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> create({
    required String targetType,
    required String targetId,
    required String reason,
    String? description,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/reports',
      body: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
    return data;
  }

  Future<Map<String, dynamic>> list({
    String status = 'pending',
    int page = 1,
    int limit = 20,
  }) async {
    return _api.get<Map<String, dynamic>>('/reports',
        query: {'status': status, 'page': page, 'limit': limit});
  }

  Future<Map<String, dynamic>> update(String reportId, {
    required String status,
    bool deactivateUser = false,
  }) async {
    return _api.patch<Map<String, dynamic>>(
      '/reports/$reportId',
      body: {'status': status, 'deactivateUser': deactivateUser},
    );
  }
}
