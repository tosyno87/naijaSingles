import 'package:dlibphonenumber/dlibphonenumber.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final phoneUtil = PhoneNumberUtil.instance;

  group('Phone validation (dlibphonenumber)', () {
    test('valid Nigerian number is valid', () {
      final parsed = phoneUtil.parse('+2348012345678', 'NG');
      expect(phoneUtil.isValidNumber(parsed), isTrue);
    });

    test('too short number for region is invalid', () {
      final parsed = phoneUtil.parse('+234801234', 'NG');
      expect(phoneUtil.isValidNumber(parsed), isFalse);
    });

    test('valid US number is valid', () {
      final parsed = phoneUtil.parse('+12125551234', 'US');
      expect(phoneUtil.isValidNumber(parsed), isTrue);
    });
  });
}
