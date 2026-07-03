import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/messages/services/matched_user_profile_loader.dart';

void main() {
  group('MatchedUserProfileLoader', () {
    test('returns parsed profile when user document exists', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('user-b').set({
        'name': 'Ada',
        'age': 27,
        'photos': ['https://example.com/photo.jpg'],
      });

      final profile = await MatchedUserProfileLoader.load(
        firestore: firestore,
        userId: 'user-b',
        fallbackName: 'Fallback',
        fallbackAvatarUrl: 'https://example.com/fallback.jpg',
      );

      expect(profile.id, 'user-b');
      expect(profile.name, 'Ada');
      expect(profile.age, 27);
      expect(profile.imageUrl, ['https://example.com/photo.jpg']);
    });

    test('falls back to thread cache when user document is missing', () async {
      final firestore = FakeFirebaseFirestore();

      final profile = await MatchedUserProfileLoader.load(
        firestore: firestore,
        userId: 'missing-user',
        fallbackName: 'Phone User',
        fallbackAvatarUrl: 'https://example.com/avatar.jpg',
      );

      expect(profile.id, 'missing-user');
      expect(profile.name, 'Phone User');
      expect(profile.imageUrl, ['https://example.com/avatar.jpg']);
    });
  });
}
