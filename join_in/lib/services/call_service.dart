import '../core/api_client.dart';
import '../models/call_log.dart';
import '../models/paginated.dart';

class CallService {
  final ApiClient _api = ApiClient.instance;

  Future<Paginated<CallLog>> history({int page = 1, int limit = 20}) async {
    final data = await _api.get<Map<String, dynamic>>(
      '/calls/history',
      query: {'page': page, 'limit': limit},
    );
    return Paginated.fromJson(data, (json) => CallLog.fromJson(json));
  }
}
