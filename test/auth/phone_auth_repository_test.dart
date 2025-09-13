import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naijasingles/common/data/repo/phone_auth_repo.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  group('PhoneAuthRepository.isSignedIn', () {
    test('returns true when there is a current user', () async {
      final mockAuth = MockFirebaseAuth();
      final repo = PhoneAuthRepository();
      
      // Mock the auth property before calling isSignedIn
      repo.auth = mockAuth;
      when(() => mockAuth.currentUser).thenReturn(MockUser());

      final result = await repo.isSignedIn();

      expect(result, isTrue);
    });

    test('returns false when there is no current user', () async {
      final mockAuth = MockFirebaseAuth();
      final repo = PhoneAuthRepository();
      
      // Mock the auth property before calling isSignedIn
      repo.auth = mockAuth;
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repo.isSignedIn();

      expect(result, isFalse);
    });
  });
}
