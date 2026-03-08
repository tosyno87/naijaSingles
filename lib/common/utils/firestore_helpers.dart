import 'package:cloud_firestore/cloud_firestore.dart';

/// Safely converts a Firestore field to [DateTime].
///
/// Handles the common inconsistency where some documents store timestamps as
/// native Firestore [Timestamp] objects while others store ISO-8601 strings
/// (e.g. from `DateTime.now().toIso8601String()`).
///
/// Returns [fallback] (defaults to `DateTime.now()`) when the value is null or
/// cannot be parsed.
DateTime parseDateTime(Object? value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
  return fallback ?? DateTime.now();
}

/// Like [parseDateTime] but returns null when the value is absent/null rather
/// than falling back to a default.
DateTime? parseDateTimeOrNull(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}
