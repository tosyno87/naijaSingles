import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/events/presentation/utils/location_formatter.dart';

void main() {
  group('LocationFormatter', () {
    test('should return "Location TBD" for empty address', () {
      expect(LocationFormatter.formatLocation(''), 'Location TBD');
      expect(LocationFormatter.formatLocation('   '), 'Location TBD');
    });

    test('should return "Online" for online/virtual events', () {
      expect(LocationFormatter.formatLocation('Online Event'), 'Online');
      expect(LocationFormatter.formatLocation('Virtual Meeting'), 'Online');
      expect(LocationFormatter.formatLocation('online'), 'Online');
      expect(LocationFormatter.formatLocation('virtual'), 'Online');
      expect(LocationFormatter.formatLocation('Virtual'), 'Online');
    });

    test('should return "Location TBD" for placeholder patterns', () {
      expect(LocationFormatter.formatLocation('TBA'), 'Location TBD');
      expect(LocationFormatter.formatLocation('TBD'), 'Location TBD');
      expect(
          LocationFormatter.formatLocation('To be announced'), 'Location TBD');
      expect(
          LocationFormatter.formatLocation('To be determined'), 'Location TBD');
      expect(LocationFormatter.formatLocation('location'), 'Location TBD');
      expect(LocationFormatter.formatLocation('address'), 'Location TBD');
    });

    test('should detect malformed locations with repeated short words', () {
      expect(LocationFormatter.formatLocation('ree, re, re'), 'Location TBD');
      expect(LocationFormatter.formatLocation('abc, def, ghi'), 'Location TBD');
    });

    test('should detect malformed locations with excessive repetition', () {
      expect(LocationFormatter.formatLocation('abc, def, abc, def'),
          'Location TBD');
      // Note: "test, test, test, other" has 2 unique words out of 4 (50%),
      // which doesn't meet the < 50% threshold, so it's considered valid
      expect(
          LocationFormatter.formatLocation('test, test, test'), 'Location TBD');
      expect(LocationFormatter.formatLocation('a, a, a, a'), 'Location TBD');
    });

    test('should return valid addresses as-is', () {
      expect(
        LocationFormatter.formatLocation('123 Main St, New York, NY'),
        '123 Main St, New York, NY',
      );
      expect(
        LocationFormatter.formatLocation('Lagos, Nigeria'),
        'Lagos, Nigeria',
      );
      expect(
        LocationFormatter.formatLocation('Victoria Island, Lagos'),
        'Victoria Island, Lagos',
      );
    });

    test('should handle addresses with extra whitespace', () {
      expect(
        LocationFormatter.formatLocation('  123 Main St, New York  '),
        '123 Main St, New York',
      );
    });

    test('should prioritize "Online" over "TBD" for online events', () {
      expect(LocationFormatter.formatLocation('Online - TBA'), 'Online');
      expect(LocationFormatter.formatLocation('Virtual Event - TBD'), 'Online');
    });
  });
}
