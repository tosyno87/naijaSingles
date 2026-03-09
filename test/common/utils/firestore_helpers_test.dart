import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/utils/firestore_helpers.dart';

/// Matches a [DateTime] whose [millisecondsSinceEpoch] equals [expected],
/// regardless of the `isUtc` flag.
Matcher _equalsMillis(int expected) => predicate<DateTime>(
      (dt) => dt.millisecondsSinceEpoch == expected,
      'has millisecondsSinceEpoch == $expected',
    );

void main() {
  // A fixed reference point used across most assertions.
  final epoch = DateTime.utc(2025, 6, 15, 12);
  final epochMillis = epoch.millisecondsSinceEpoch;
  final epochSeconds = epochMillis ~/ 1000;

  // -----------------------------------------------------------------------
  // parseDateTime
  // -----------------------------------------------------------------------
  group('parseDateTime', () {
    test('returns fallback (default DateTime.now()) for null', () {
      final before = DateTime.now().millisecondsSinceEpoch;
      final result = parseDateTime(null);
      final after = DateTime.now().millisecondsSinceEpoch;
      expect(result.millisecondsSinceEpoch, greaterThanOrEqualTo(before));
      expect(result.millisecondsSinceEpoch, lessThanOrEqualTo(after));
    });

    test('returns explicit fallback for null', () {
      final fallback = DateTime.utc(2000);
      expect(parseDateTime(null, fallback: fallback), equals(fallback));
    });

    test('handles Timestamp', () {
      final ts = Timestamp.fromDate(epoch);
      expect(parseDateTime(ts), _equalsMillis(epochMillis));
    });

    test('handles DateTime pass-through', () {
      expect(parseDateTime(epoch), same(epoch));
    });

    test('handles int (epoch millis)', () {
      expect(parseDateTime(epochMillis), _equalsMillis(epochMillis));
    });

    test('handles ISO-8601 String', () {
      expect(
        parseDateTime(epoch.toIso8601String()),
        _equalsMillis(epochMillis),
      );
    });

    test('returns fallback for unparseable String', () {
      final fb = DateTime.utc(2000);
      expect(parseDateTime('not-a-date', fallback: fb), equals(fb));
    });

    // -- Map: millisecondsSinceEpoch variants --

    test('handles Map with int millisecondsSinceEpoch', () {
      expect(
        parseDateTime({'millisecondsSinceEpoch': epochMillis}),
        _equalsMillis(epochMillis),
      );
    });

    test('handles Map with double millisecondsSinceEpoch', () {
      expect(
        parseDateTime({'millisecondsSinceEpoch': epochMillis.toDouble()}),
        _equalsMillis(epochMillis),
      );
    });

    test('handles Map with String millisecondsSinceEpoch', () {
      expect(
        parseDateTime({'millisecondsSinceEpoch': epochMillis.toString()}),
        _equalsMillis(epochMillis),
      );
    });

    // -- Map: _seconds / _nanoseconds variants --

    test('handles Map with _seconds and _nanoseconds', () {
      expect(
        parseDateTime({'_seconds': epochSeconds, '_nanoseconds': 0}),
        _equalsMillis(epochSeconds * 1000),
      );
    });

    test('handles Map with _seconds only (no _nanoseconds)', () {
      expect(
        parseDateTime({'_seconds': epochSeconds}),
        _equalsMillis(epochSeconds * 1000),
      );
    });

    test('handles Map with _seconds as String', () {
      expect(
        parseDateTime({'_seconds': epochSeconds.toString()}),
        _equalsMillis(epochSeconds * 1000),
      );
    });

    test('handles Map with _seconds and _nanoseconds contributing millis', () {
      const nanos = 500000000; // 500ms
      expect(
        parseDateTime({'_seconds': epochSeconds, '_nanoseconds': nanos}),
        _equalsMillis(epochSeconds * 1000 + 500),
      );
    });

    // -- Map: malformed --

    test('returns fallback for empty Map', () {
      final fb = DateTime.utc(2000);
      expect(parseDateTime(<String, dynamic>{}, fallback: fb), equals(fb));
    });

    test('returns fallback for Map with unrecognised keys', () {
      final fb = DateTime.utc(2000);
      expect(parseDateTime({'foo': 'bar'}, fallback: fb), equals(fb));
    });

    test('returns fallback for Map with non-numeric millisecondsSinceEpoch',
        () {
      final fb = DateTime.utc(2000);
      expect(
        parseDateTime({'millisecondsSinceEpoch': 'abc'}, fallback: fb),
        equals(fb),
      );
    });

    test('returns fallback for Map with fractional double millis', () {
      final fb = DateTime.utc(2000);
      expect(
        parseDateTime(
          {'millisecondsSinceEpoch': 1234.9},
          fallback: fb,
        ),
        equals(fb),
      );
    });

    test('returns fallback for Map with non-numeric _seconds', () {
      final fb = DateTime.utc(2000);
      expect(
        parseDateTime({'_seconds': 'abc'}, fallback: fb),
        equals(fb),
      );
    });

    // -- Unrecognised types --

    test('returns fallback for unrecognised type (bool)', () {
      final fb = DateTime.utc(2000);
      expect(parseDateTime(true, fallback: fb), equals(fb));
    });

    test('returns fallback for unrecognised type (List)', () {
      final fb = DateTime.utc(2000);
      expect(parseDateTime([1, 2, 3], fallback: fb), equals(fb));
    });
  });

  // -----------------------------------------------------------------------
  // parseDateTimeOrNull
  // -----------------------------------------------------------------------
  group('parseDateTimeOrNull', () {
    test('returns null for null', () {
      expect(parseDateTimeOrNull(null), isNull);
    });

    test('handles Timestamp', () {
      final ts = Timestamp.fromDate(epoch);
      expect(parseDateTimeOrNull(ts), _equalsMillis(epochMillis));
    });

    test('handles DateTime pass-through', () {
      expect(parseDateTimeOrNull(epoch), same(epoch));
    });

    test('handles int (epoch millis)', () {
      expect(parseDateTimeOrNull(epochMillis), _equalsMillis(epochMillis));
    });

    test('handles ISO-8601 String', () {
      expect(
        parseDateTimeOrNull(epoch.toIso8601String()),
        _equalsMillis(epochMillis),
      );
    });

    test('returns null for unparseable String', () {
      expect(parseDateTimeOrNull('not-a-date'), isNull);
    });

    // -- Map: millisecondsSinceEpoch variants --

    test('handles Map with int millisecondsSinceEpoch', () {
      expect(
        parseDateTimeOrNull({'millisecondsSinceEpoch': epochMillis}),
        _equalsMillis(epochMillis),
      );
    });

    test('handles Map with double millisecondsSinceEpoch', () {
      expect(
        parseDateTimeOrNull({'millisecondsSinceEpoch': epochMillis.toDouble()}),
        _equalsMillis(epochMillis),
      );
    });

    test('handles Map with String millisecondsSinceEpoch', () {
      expect(
        parseDateTimeOrNull(
          {'millisecondsSinceEpoch': epochMillis.toString()},
        ),
        _equalsMillis(epochMillis),
      );
    });

    // -- Map: _seconds / _nanoseconds variants --

    test('handles Map with _seconds and _nanoseconds', () {
      expect(
        parseDateTimeOrNull({'_seconds': epochSeconds, '_nanoseconds': 0}),
        _equalsMillis(epochSeconds * 1000),
      );
    });

    test('handles Map with _seconds only (no _nanoseconds)', () {
      expect(
        parseDateTimeOrNull({'_seconds': epochSeconds}),
        _equalsMillis(epochSeconds * 1000),
      );
    });

    // -- Map: malformed --

    test('returns null for empty Map', () {
      expect(parseDateTimeOrNull(<String, dynamic>{}), isNull);
    });

    test('returns null for Map with unrecognised keys', () {
      expect(parseDateTimeOrNull({'foo': 'bar'}), isNull);
    });

    test('returns null for Map with non-numeric millisecondsSinceEpoch', () {
      expect(parseDateTimeOrNull({'millisecondsSinceEpoch': 'abc'}), isNull);
    });

    test('returns null for Map with fractional double millis', () {
      expect(
        parseDateTimeOrNull({'millisecondsSinceEpoch': 1234.9}),
        isNull,
      );
    });

    test('returns null for Map with non-numeric _seconds', () {
      expect(parseDateTimeOrNull({'_seconds': 'abc'}), isNull);
    });

    // -- Unrecognised types --

    test('returns null for unrecognised type (bool)', () {
      expect(parseDateTimeOrNull(true), isNull);
    });

    test('returns null for unrecognised type (List)', () {
      expect(parseDateTimeOrNull([1, 2, 3]), isNull);
    });
  });
}
