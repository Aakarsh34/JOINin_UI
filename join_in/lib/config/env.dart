import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String? _safe(String key) {
    try {
      return dotenv.maybeGet(key);
    } catch (_) {
      return null;
    }
  }

  static String get apiBaseUrl =>
      _safe('API_BASE_URL') ??
      'https://joininbackend-production.up.railway.app';

  static String get socketUrl => _safe('SOCKET_URL') ?? apiBaseUrl;

  static String get defaultCountryCode => _safe('DEFAULT_COUNTRY_CODE') ?? '+91';

  static bool get enableHttpLogging =>
      (_safe('ENABLE_HTTP_LOGGING') ?? 'false').toLowerCase() == 'true';
}
