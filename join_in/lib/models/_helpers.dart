DateTime? parseIsoDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String stringFromJson(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

int intFromJson(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double doubleFromJson(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

bool boolFromJson(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final raw = value.toString().toLowerCase();
  return raw == 'true' || raw == '1';
}

List<String> stringListFromJson(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}

String? extractId(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map) return value['_id']?.toString() ?? value['id']?.toString();
  return null;
}
