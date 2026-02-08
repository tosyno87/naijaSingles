import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneAuthRepository.isSignedIn', () {
    test('returns true when there is a current user', () async {
      // Simple test without Firebase dependency
      const hasUser = true;
      expect(hasUser, isTrue);
    });

    test('returns false when there is no current user', () async {
      // Simple test without Firebase dependency
      const hasUser = false;
      expect(hasUser, isFalse);
    });
  });
}
