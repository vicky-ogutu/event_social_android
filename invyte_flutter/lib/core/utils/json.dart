/// Lenient JSON readers.
///
/// The backend is backed by MySQL, so booleans arrive as `0/1`, decimals as
/// strings and ids occasionally as strings. These helpers normalise that.
typedef Json = Map<String, dynamic>;

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is bool) return value ? 1 : 0;
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  }
  return fallback;
}

int? asIntOrNull(Object? value) => value == null ? null : asInt(value);

double asDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? asDoubleOrNull(Object? value) => value == null ? null : asDouble(value);

bool asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value == 'true' || value == '1';
  return false;
}

String asString(Object? value, [String fallback = '']) =>
    value == null ? fallback : value.toString();

String? asStringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

Json asJson(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<T> asList<T>(Object? value, T Function(Json json) parse) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((e) => parse(Map<String, dynamic>.from(e))).toList();
}

List<String> asStringList(Object? value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];

DateTime? asDateTime(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// Parses the calendar date part only (`2025-06-01` or
/// `2025-06-01T00:00:00.000Z`) so time zones can't shift the day.
DateTime? asDate(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.length < 10) return null;
  final parts = text.substring(0, 10).split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

String toApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
