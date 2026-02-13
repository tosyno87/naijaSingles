import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/utils/profile_completion_guard.dart';
import 'package:naijasingles/models/user_model.dart';

void main() {
  group('ProfileCompletionGuard', () {
    test(
        'isDocumentComplete returns true when explicit completion flag is true',
        () {
      expect(
        ProfileCompletionGuard.isDocumentComplete({
          'name': 'Tosin',
          'onboardingCompleted': true,
        }),
        isTrue,
      );
    });

    test(
        'isDocumentComplete returns false when explicit completion flag is false',
        () {
      expect(
        ProfileCompletionGuard.isDocumentComplete({
          'name': 'Tosin',
          'isProfileComplete': false,
          'photos': ['https://example.com/photo.jpg'],
        }),
        isFalse,
      );
    });

    test('isDocumentComplete uses fallback name + gender/photo checks', () {
      expect(
        ProfileCompletionGuard.isDocumentComplete({
          'name': 'Tosin',
          'userGender': 'male',
        }),
        isTrue,
      );

      expect(
        ProfileCompletionGuard.isDocumentComplete({
          'name': 'Tosin',
          'photos': ['https://example.com/photo.jpg'],
        }),
        isTrue,
      );

      expect(
        ProfileCompletionGuard.isDocumentComplete({
          'name': 'Tosin',
        }),
        isFalse,
      );
    });

    test('isUserComplete requires name and gender/photo', () {
      final completeWithGender = UserModel(
        id: '1',
        name: 'Tosin',
        userGender: 'male',
      );
      final completeWithPhoto = UserModel(
        id: '2',
        name: 'Tosin',
        imageUrl: const ['https://example.com/photo.jpg'],
      );
      final incomplete = UserModel(
        id: '3',
        name: 'Tosin',
      );

      expect(ProfileCompletionGuard.isUserComplete(completeWithGender), isTrue);
      expect(ProfileCompletionGuard.isUserComplete(completeWithPhoto), isTrue);
      expect(ProfileCompletionGuard.isUserComplete(incomplete), isFalse);
    });
  });
}
