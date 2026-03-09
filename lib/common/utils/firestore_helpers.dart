import 'package:cloud_firestore/cloud_firestore.dart';

/// Safely converts a Firestore field to [DateTime].
///
/// Firestore documents may store date values in several forms depending on how
/// they were written (SDK, REST, Cloud Functions, manual seed scripts, etc.).
/// This helper normalises all common representations into a [DateTime]:
///
///  * [Timestamp] – native Firestore timestamp
///  * [DateTime]  – already a Dart DateTime (pass-through)
///  * [int]       – epoch milliseconds
///  * [String]    – ISO-8601 formatted string
///  * [Map]       – see [_dateTimeFromMap] for the supported map layouts
///
/// Returns [fallback] (defaults to `DateTime.now()`) when the value is null,
/// an unrecognised type, or cannot be parsed.
DateTime parseDateTime(Object? value, {DateTime? fallback}) {
  if (value == null) return fallback ?? DateTime.now();

  if (value is Timestamp) {
    try {
      return value.toDate();
    } on Exception {
      return fallback ?? DateTime.now();
    }
  }

  if (value is DateTime) return value;

  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } on Exception {
      return fallback ?? DateTime.now();
    }
  }

  if (value is String) {
    return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
  }

  if (value is Map) {
    return _dateTimeFromMap(value) ?? fallback ?? DateTime.now();
  }

  return fallback ?? DateTime.now();
}

/// Like [parseDateTime] but returns `null` when the value is absent, null, or
/// an unrecognised type rather than falling back to a default.
DateTime? parseDateTimeOrNull(Object? value) {
  if (value == null) return null;

  if (value is Timestamp) {
    try {
      return value.toDate();
    } on Exception {
      return null;
    }
  }

  if (value is DateTime) return value;

  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } on Exception {
      return null;
    }
  }

  if (value is String) return DateTime.tryParse(value);

  if (value is Map) return _dateTimeFromMap(value);

  return null;
}

// ---------------------------------------------------------------------------
// Map helpers
// ---------------------------------------------------------------------------

/// Attempts to extract a [DateTime] from a [Map] using two known layouts:
///
/// 1. **`millisecondsSinceEpoch`** – value may be [int], [double], or a
///    numeric [String].  Produced by `DateTime.millisecondsSinceEpoch` or
///    manual seed data.
///
/// 2. **`_seconds` / `_nanoseconds`** – the serialised form of a Firestore
///    [Timestamp] when encoded via `toJson()` or returned by the REST API /
///    Cloud Functions.  `_nanoseconds` is optional (defaults to 0).
///
/// Returns `null` if the map matches neither layout or if parsing fails.
DateTime? _dateTimeFromMap(Map<dynamic, dynamic> map) {
  // Layout 1 – millisecondsSinceEpoch
  if (map.containsKey('millisecondsSinceEpoch')) {
    final millis = _toInt(map['millisecondsSinceEpoch']);
    if (millis != null) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      } on Exception {
        return null;
      }
    }
  }

  // Layout 2 – _seconds (+ optional _nanoseconds)
  if (map.containsKey('_seconds')) {
    final seconds = _toInt(map['_seconds']);
    if (seconds != null) {
      final nanos = _toInt(map['_nanoseconds']) ?? 0;
      try {
        return DateTime.fromMillisecondsSinceEpoch(
          seconds * 1000 + nanos ~/ 1000000,
        );
      } on Exception {
        return null;
      }
    }
  }

  return null;
}

/// Coerces [value] to [int] when it is an [int], a whole-number [double]
/// (e.g. `1234.0`), or a numeric [String] that [int.tryParse] accepts.
///
/// Fractional doubles like `1234.9` are rejected (returns `null`) to avoid
/// silently dropping precision.
int? _toInt(Object? value) {
  if (value is int) return value;
  if (value is double) {
    return value == value.truncateToDouble() ? value.toInt() : null;
  }
  if (value is String) return int.tryParse(value);
  return null;
}
