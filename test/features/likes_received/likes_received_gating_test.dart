import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/likes_received/likes_received_gating.dart';

void main() {
  group('LikesReceivedGating', () {
    test('free user sees first liker only unlocked', () {
      expect(
        LikesReceivedGating.isCardLocked(hasPremiumAccess: false, index: 0),
        false,
      );
      expect(
        LikesReceivedGating.isCardLocked(hasPremiumAccess: false, index: 1),
        true,
      );
    });

    test('premium user sees all likers unlocked', () {
      expect(
        LikesReceivedGating.isCardLocked(hasPremiumAccess: true, index: 0),
        false,
      );
      expect(
        LikesReceivedGating.isCardLocked(hasPremiumAccess: true, index: 5),
        false,
      );
    });

    test('visibleCount respects premium', () {
      expect(
        LikesReceivedGating.visibleCount(
          hasPremiumAccess: false,
          totalLikers: 10,
        ),
        1,
      );
      expect(
        LikesReceivedGating.visibleCount(
          hasPremiumAccess: true,
          totalLikers: 10,
        ),
        10,
      );
    });
  });
}
