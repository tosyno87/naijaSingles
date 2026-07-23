import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/data/repo/privacy_aware_user_search_repo.dart';
import 'package:naijasingles/models/user_model.dart';
import 'package:naijasingles/services/location_privacy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  late FakeFirebaseFirestore fakeDb;

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
    PrivacyAwareUserSearchRepo.db = fakeDb;
  });

  UserModel seeker({
    String id = 'seeker1',
    double lat = 29.7600771,
    double lng = -95.3701108,
    int maxDistance = 50,
    String showGender = 'everyone',
    String lookingFor = 'Dating',
    Map<String, dynamic>? ageRange,
    bool strictDistance = false,
  }) {
    return UserModel(
      id: id,
      name: 'Seeker',
      latitude: lat,
      longitude: lng,
      maxDistance: maxDistance,
      showGender: showGender,
      lookingFor: lookingFor,
      ageRange: ageRange ?? <String, dynamic>{'min': 25, 'max': 45},
      strictDistance: strictDistance,
    );
  }

  Future<void> seedUser({
    required String id,
    required double lat,
    required double lng,
    int age = 30,
    String gender = 'female',
    String lookingFor = 'Dating',
    bool discoverable = true,
  }) async {
    final String geoHash = LocationPrivacyService.generateGeoHash(
      lat,
      lng,
      LocationPrecision.medium,
    );
    await fakeDb.collection('users').doc(id).set(<String, dynamic>{
      'name': 'User $id',
      'age': age,
      'userGender': gender,
      'lookingFor': lookingFor,
      'isDiscoverable': discoverable,
      'isBlocked': false,
      'latitude': lat,
      'longitude': lng,
      'location': <String, dynamic>{
        'latitude': lat,
        'longitude': lng,
        'address': 'Test City',
      },
      'geoHash': geoHash,
      'photos': <String>['https://example.com/$id.jpg'],
      'Pictures': <String>['https://example.com/$id.jpg'],
      'accountStatus': 'active',
    });
  }

  group('PrivacyAwareUserSearchRepo.applyDiscoveryPreferences', () {
    test('keeps candidates matching gender, intent, and age', () {
      final UserModel current = seeker(showGender: 'women');
      final List<UserModel> result =
          PrivacyAwareUserSearchRepo.applyDiscoveryPreferences(
        <UserModel>[
          UserModel(
            id: 'a',
            name: 'A',
            age: 30,
            userGender: 'female',
            lookingFor: 'Dating',
          ),
          UserModel(
            id: 'b',
            name: 'B',
            age: 30,
            userGender: 'male',
            lookingFor: 'Dating',
          ),
          UserModel(
            id: 'c',
            name: 'C',
            age: 60,
            userGender: 'female',
            lookingFor: 'Dating',
          ),
          UserModel(
            id: 'd',
            name: 'D',
            age: 30,
            userGender: 'female',
            lookingFor: 'Friendship',
          ),
        ],
        current,
        'Dating',
      );

      expect(result.map((UserModel u) => u.id), <String>['a']);
    });
  });

  group('PrivacyAwareUserSearchRepo.createUserModelFromFilteredData', () {
    test('prefers exact lat/lng over geoHash', () async {
      final UserModel user =
          await PrivacyAwareUserSearchRepo.createUserModelFromFilteredData(
        <String, dynamic>{
          'name': 'Exact',
          'age': 28,
          'latitude': 29.7,
          'longitude': -95.3,
          'geoHash': LocationPrivacyService.generateGeoHash(
            33.7,
            -84.3,
            LocationPrecision.medium,
          ),
          'photos': <String>['https://example.com/a.jpg'],
          'lookingFor': 'Dating',
        },
        'uid1',
      );

      expect(user.latitude, 29.7);
      expect(user.longitude, -95.3);
      expect(user.name, 'Exact');
    });

    test('falls back to geoHash when lat/lng missing', () async {
      final String geoHash = LocationPrivacyService.generateGeoHash(
        29.76,
        -95.37,
        LocationPrecision.medium,
      );
      final UserModel user =
          await PrivacyAwareUserSearchRepo.createUserModelFromFilteredData(
        <String, dynamic>{
          'name': 'Hash',
          'age': 28,
          'geoHash': geoHash,
          'photos': <String>['https://example.com/a.jpg'],
        },
        'uid2',
      );

      expect(user.latitude, isNotNull);
      expect(user.longitude, isNotNull);
    });
  });

  group('PrivacyAwareUserSearchRepo.getUserList', () {
    test('returns nearby discoverable users within max distance', () async {
      final UserModel current = seeker(maxDistance: 100);
      // ~same Houston area as seeker
      await seedUser(
        id: 'near1',
        lat: 29.761,
        lng: -95.371,
        age: 30,
        gender: 'female',
      );

      final List<UserModel> result =
          await PrivacyAwareUserSearchRepo.getUserList(current);

      expect(result.any((UserModel u) => u.id == 'near1'), isTrue);
    });

    test('soft-expands to nearest matching prefs when none in range', () async {
      final UserModel current = seeker(maxDistance: 10);
      // Los Angeles — far outside 10mi of Houston
      await seedUser(
        id: 'far1',
        lat: 34.0522,
        lng: -118.2437,
        age: 32,
        gender: 'female',
        lookingFor: 'Dating',
      );
      // Wrong age — must not win soft expand
      await seedUser(
        id: 'far_old',
        lat: 34.06,
        lng: -118.25,
        age: 70,
        gender: 'female',
      );

      final List<UserModel> result =
          await PrivacyAwareUserSearchRepo.getUserList(current);

      expect(result.map((UserModel u) => u.id), contains('far1'));
      expect(result.map((UserModel u) => u.id), isNot(contains('far_old')));
    });

    test('does not soft-expand when strict distance is enabled', () async {
      final UserModel current = seeker(maxDistance: 10, strictDistance: true);
      await seedUser(
        id: 'far_strict',
        lat: 34.0522,
        lng: -118.2437,
        age: 32,
        gender: 'female',
      );

      final List<UserModel> result =
          await PrivacyAwareUserSearchRepo.getUserList(current);

      expect(result, isEmpty);
    });

    test('excludes checked and matched users', () async {
      final UserModel current = seeker(maxDistance: 100);
      await seedUser(
        id: 'near_checked',
        lat: 29.761,
        lng: -95.371,
        age: 30,
      );
      await fakeDb
          .collection('users')
          .doc(current.id)
          .collection('CheckedUser')
          .doc('near_checked')
          .set(<String, dynamic>{'LikedUser': 'near_checked'});

      final List<UserModel> result =
          await PrivacyAwareUserSearchRepo.getUserList(current);

      expect(
          result.map((UserModel u) => u.id), isNot(contains('near_checked')));
    });

    test('continues after nearby gender mismatch to find broader match',
        () async {
      final UserModel current = seeker(
        maxDistance: 50,
        showGender: 'women',
      );
      // Nearby but wrong gender
      await seedUser(
        id: 'near_man',
        lat: 29.761,
        lng: -95.371,
        age: 30,
        gender: 'male',
      );
      // Far but matching woman (soft expand)
      await seedUser(
        id: 'far_woman',
        lat: 34.0522,
        lng: -118.2437,
        age: 30,
        gender: 'female',
      );

      final List<UserModel> result =
          await PrivacyAwareUserSearchRepo.getUserList(current);

      expect(result.map((UserModel u) => u.id), contains('far_woman'));
      expect(result.map((UserModel u) => u.id), isNot(contains('near_man')));
    });
  });
}
