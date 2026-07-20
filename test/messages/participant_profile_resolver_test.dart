import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
      expect(
          ParticipantProfileResolver.isPlaceholderName('Phone User'), isTrue);
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
        ParticipantProfileResolver.readFirstPhotoForTest(
            {'photos': <String>[]}),
        isNull,
      );
    });
  });

  group('ParticipantProfileResolver.ensureMatchMirrors', () {
    test('does not write mirrors without a top-level match', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      final ParticipantProfileResolver resolver =
          ParticipantProfileResolver(firestore: firestore);

      await resolver.ensureMatchMirrors(
        currentUserId: 'a',
        otherUserId: 'b',
      );

      final snap = await firestore
          .collection('users')
          .doc('a')
          .collection('Matches')
          .doc('b')
          .get();
      expect(snap.exists, isFalse);
    });

    test('writes mirrors when modern matches doc exists', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await firestore.collection('matches').doc('m1').set({
        'users': <String>['a', 'b'],
      });
      final ParticipantProfileResolver resolver =
          ParticipantProfileResolver(firestore: firestore);

      await resolver.ensureMatchMirrors(
        currentUserId: 'a',
        otherUserId: 'b',
      );

      expect(
        (await firestore
                .collection('users')
                .doc('a')
                .collection('Matches')
                .doc('b')
                .get())
            .exists,
        isTrue,
      );
      expect(
        (await firestore
                .collection('users')
                .doc('b')
                .collection('Matches')
                .doc('a')
                .get())
            .exists,
        isTrue,
      );
    });

    test('uses preloaded matchedPeerIds without rewriting for non-peers',
        () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await firestore.collection('matches').doc('m1').set({
        'users': <String>['a', 'b'],
      });
      final ParticipantProfileResolver resolver =
          ParticipantProfileResolver(firestore: firestore);

      final Set<String> peers = await resolver.loadMatchedPeerIds('a');
      expect(peers, contains('b'));

      await resolver.ensureMatchMirrors(
        currentUserId: 'a',
        otherUserId: 'forged',
        matchedPeerIds: peers,
      );
      expect(
        (await firestore
                .collection('users')
                .doc('a')
                .collection('Matches')
                .doc('forged')
                .get())
            .exists,
        isFalse,
      );

      await resolver.ensureMatchMirrors(
        currentUserId: 'a',
        otherUserId: 'b',
        matchedPeerIds: peers,
      );
      expect(
        (await firestore
                .collection('users')
                .doc('a')
                .collection('Matches')
                .doc('b')
                .get())
            .exists,
        isTrue,
      );
    });

    test('skips match scan when both mirrors already exist', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('a')
          .collection('Matches')
          .doc('b')
          .set({'Matches': 'b'});
      await firestore
          .collection('users')
          .doc('b')
          .collection('Matches')
          .doc('a')
          .set({'Matches': 'a'});
      final ParticipantProfileResolver resolver =
          ParticipantProfileResolver(firestore: firestore);

      await resolver.ensureMatchMirrors(
        currentUserId: 'a',
        otherUserId: 'b',
        matchedPeerIds: <String>{},
      );

      expect(
        (await firestore
                .collection('users')
                .doc('a')
                .collection('Matches')
                .doc('b')
                .get())
            .exists,
        isTrue,
      );
    });

    test('repairs missing opposite mirror when local mirror exists', () async {
      final FakeFirebaseFirestore firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('a')
          .collection('Matches')
          .doc('b')
          .set({'Matches': 'b'});
      final ParticipantProfileResolver resolver =
          ParticipantProfileResolver(firestore: firestore);

      await resolver.ensureMatchMirrors(
        currentUserId: 'a',
        otherUserId: 'b',
        matchedPeerIds: <String>{},
      );

      expect(
        (await firestore
                .collection('users')
                .doc('b')
                .collection('Matches')
                .doc('a')
                .get())
            .exists,
        isTrue,
      );
    });
  });
}
