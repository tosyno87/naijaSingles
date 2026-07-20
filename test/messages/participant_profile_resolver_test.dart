import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/messages/services/participant_profile_resolver.dart';

void main() {
  group('ParticipantProfileResolver field readers', () {
    test('reads name from name or UserName', () {
      expect(
        ParticipantProfileResolver.readNameForTest({'name': '  Obatos  '}),
        'Obatos',
      );
      expect(
        ParticipantProfileResolver.readNameForTest({'UserName': 'Wizkid'}),
        'Wizkid',
      );
      expect(
        ParticipantProfileResolver.readNameForTest({'displayName': 'Ada'}),
        'Ada',
      );
      expect(
        ParticipantProfileResolver.readNameForTest({'name': ''}),
        isNull,
      );
      expect(
        ParticipantProfileResolver.readNameForTest({'name': 'Phone User'}),
        isNull,
      );
    });

    test('treats placeholder labels as empty', () {
      expect(ParticipantProfileResolver.isPlaceholderName('Phone User'), isTrue);
      expect(ParticipantProfileResolver.isPlaceholderName('User'), isTrue);
      expect(ParticipantProfileResolver.isPlaceholderName('Obatos'), isFalse);
    });

    test('reads first photo from photos or Pictures', () {
      expect(
        ParticipantProfileResolver.readFirstPhotoForTest({
          'photos': <String>['https://cdn.example/a.jpg'],
        }),
        'https://cdn.example/a.jpg',
      );
      expect(
        ParticipantProfileResolver.readFirstPhotoForTest({
          'Pictures': <String>['https://cdn.example/b.jpg'],
        }),
        'https://cdn.example/b.jpg',
      );
      expect(
        ParticipantProfileResolver.readFirstPhotoForTest({'photos': <String>[]}),
        isNull,
      );
    });
  });
}
