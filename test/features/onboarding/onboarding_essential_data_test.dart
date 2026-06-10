import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/onboarding/bloc/onboarding_data.dart';
import 'package:naijasingles/features/onboarding/data/repositories/onboarding_repository.dart';

void main() {
  group('OnboardingRepository essential data', () {
    final repository = OnboardingRepository();

    test('persists gender fields required for discovery queries', () {
      final data = OnboardingData(
        fullName: 'Amina',
        dateOfBirth: DateTime(1995, 3, 15),
        gender: 'Female',
        interestedIn: 'Male',
        bio: 'Building meaningful connections in the diaspora.',
        interests: const ['music', 'travel', 'food'],
        nationality: 'Nigeria',
        locationName: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
        maxDistance: 50,
      );

      final payload = repository.buildEssentialDataForTesting(data);

      expect(payload['userGender'], 'Female');
      expect(payload['gender'], 'Female');
      expect(payload['showGender'], 'Male');
      expect(payload['editInfo'], isA<Map>());
      expect(payload['editInfo']['userGender'], 'Female');
      expect(payload['onboardingCompleted'], isTrue);
    });
  });
}
