import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/features/profile/profile_screen.dart';

Widget _buildApp({
  required ProfileScreen screen,
}) =>
    MaterialApp(
      home: screen,
      routes: {
        '/events': (_) => const Scaffold(body: Text('Events')),
      },
    );

/// Pumps enough frames for Firestore snapshot to propagate without waiting
/// for network-bound image widgets to settle.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  const testUid = 'test-user-123';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    final mockUser = MockUser(uid: testUid);
    mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
  });

  group('ProfileScreen', () {
    testWidgets('shows loading indicator before data arrives', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          screen: ProfileScreen(
            auth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders profile with string data', (tester) async {
      await fakeFirestore.collection('users').doc(testUid).set({
        'name': 'Ada Obi',
        'age': 28,
        'nationality': 'Nigerian',
        'location': 'London',
        'bio': 'Hello world',
        'interests': ['Music', 'Travel'],
        'photos': ['https://example.com/photo1.jpg'],
      });

      await tester.pumpWidget(
        _buildApp(
          screen: ProfileScreen(
            auth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
      );
      await pumpUntilFound(tester, find.text('Ada Obi, 28'));

      expect(find.text('Ada Obi, 28'), findsOneWidget);
      expect(find.text('Nigerian'), findsOneWidget);
      expect(find.text('London'), findsOneWidget);
      expect(find.text('Hello world'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);
      expect(find.text('Travel'), findsOneWidget);
    });

    testWidgets('renders nationality correctly when stored as Map',
        (tester) async {
      await fakeFirestore.collection('users').doc(testUid).set({
        'name': 'Kemi',
        'nationality': {'name': 'Ghanaian', 'code': 'GH'},
        'photos': ['https://example.com/photo1.jpg'],
      });

      await tester.pumpWidget(
        _buildApp(
          screen: ProfileScreen(
            auth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
      );
      await pumpUntilFound(tester, find.text('Ghanaian'));

      expect(find.text('Ghanaian'), findsOneWidget);
      expect(find.textContaining('{'), findsNothing);
    });

    testWidgets('renders location correctly when stored as Map',
        (tester) async {
      await fakeFirestore.collection('users').doc(testUid).set({
        'name': 'Tobi',
        'location': {'name': 'Manchester', 'lat': 53.48},
        'photos': ['https://example.com/photo1.jpg'],
      });

      await tester.pumpWidget(
        _buildApp(
          screen: ProfileScreen(
            auth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
      );
      await pumpUntilFound(tester, find.text('Manchester'));

      expect(find.text('Manchester'), findsOneWidget);
      expect(find.textContaining('{'), findsNothing);
    });

    testWidgets('shows Add Photos placeholder when profile has no photos',
        (tester) async {
      await fakeFirestore.collection('users').doc(testUid).set({
        'name': 'Empty User',
        'photos': <String>[],
      });

      await tester.pumpWidget(
        _buildApp(
          screen: ProfileScreen(
            auth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Photos'), findsOneWidget);
    });

    testWidgets('does not crash when user doc has no fields', (tester) async {
      await fakeFirestore.collection('users').doc(testUid).set({});

      await tester.pumpWidget(
        _buildApp(
          screen: ProfileScreen(
            auth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Name'), findsOneWidget);
      expect(find.text('Add Photos'), findsOneWidget);
    });

    testWidgets('Edit Profile button is present', (tester) async {
      await fakeFirestore.collection('users').doc(testUid).set({
        'name': 'User',
        'photos': <String>[],
      });

      await tester.pumpWidget(
        _buildApp(
          screen: ProfileScreen(
            auth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('realtime Firestore update refreshes the UI', (tester) async {
      await fakeFirestore.collection('users').doc(testUid).set({
        'name': 'Before Edit',
        'photos': <String>[],
      });

      await tester.pumpWidget(
        _buildApp(
          screen: ProfileScreen(
            auth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Before Edit'), findsOneWidget);

      await fakeFirestore.collection('users').doc(testUid).update({
        'name': 'After Edit',
      });
      await tester.pumpAndSettle();

      expect(find.text('After Edit'), findsOneWidget);
      expect(find.text('Before Edit'), findsNothing);
    });

    testWidgets('falls back to living_in when location is empty',
        (tester) async {
      await fakeFirestore.collection('users').doc(testUid).set({
        'name': 'Tunde',
        'living_in': 'Lagos',
        'photos': ['https://example.com/p.jpg'],
      });

      await tester.pumpWidget(
        _buildApp(
          screen: ProfileScreen(
            auth: mockAuth,
            firestore: fakeFirestore,
          ),
        ),
      );
      await pumpUntilFound(tester, find.text('Lagos'));

      expect(find.text('Lagos'), findsOneWidget);
    });
  });
}
