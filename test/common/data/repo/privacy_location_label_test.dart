import 'package:flutter_test/flutter_test.dart';
import 'package:naijasingles/common/data/repo/user_location_repo.dart';

void main() {
  group('privacyAwareLocationLabelFromResults', () {
    test('prefers city from street components over state-only result', () {
      final List<Map<String, Object?>> results = <Map<String, Object?>>[
        <String, Object?>{
          'types': <String>['street_address'],
          'address_components': <Map<String, Object?>>[
            <String, Object?>{
              'long_name': '123',
              'short_name': '123',
              'types': <String>['street_number'],
            },
            <String, Object?>{
              'long_name': 'Lyons Avenue',
              'short_name': 'Lyons Ave',
              'types': <String>['route'],
            },
            <String, Object?>{
              'long_name': 'Houston',
              'short_name': 'Houston',
              'types': <String>['locality', 'political'],
            },
            <String, Object?>{
              'long_name': 'Texas',
              'short_name': 'TX',
              'types': <String>['administrative_area_level_1', 'political'],
            },
            <String, Object?>{
              'long_name': 'United States',
              'short_name': 'US',
              'types': <String>['country', 'political'],
            },
          ],
        },
        <String, Object?>{
          'types': <String>['administrative_area_level_1', 'political'],
          'address_components': <Map<String, Object?>>[
            <String, Object?>{
              'long_name': 'Texas',
              'short_name': 'TX',
              'types': <String>['administrative_area_level_1', 'political'],
            },
            <String, Object?>{
              'long_name': 'United States',
              'short_name': 'US',
              'types': <String>['country', 'political'],
            },
          ],
        },
      ];

      expect(
        privacyAwareLocationLabelFromResults(results),
        'Houston, TX',
      );
    });

    test('pickLocalityGeocodeResult ignores state-level results', () {
      final List<Map<String, Object?>> results = <Map<String, Object?>>[
        <String, Object?>{
          'types': <String>['administrative_area_level_1', 'political'],
          'place_id': 'state',
        },
        <String, Object?>{
          'types': <String>['locality', 'political'],
          'place_id': 'city',
          'geometry': <String, Object?>{
            'location': <String, Object?>{'lat': 29.76, 'lng': -95.37},
          },
        },
      ];

      final Map<String, dynamic>? locality = pickLocalityGeocodeResult(results);
      expect(locality?['place_id'], 'city');
    });

    test('POI-style components still produce a city label', () {
      final List<dynamic> components = <Map<String, Object?>>[
        <String, Object?>{
          'long_name': 'Museum of Fine Arts',
          'short_name': 'MFA',
          'types': <String>['point_of_interest', 'establishment'],
        },
        <String, Object?>{
          'long_name': 'Houston',
          'short_name': 'Houston',
          'types': <String>['locality', 'political'],
        },
        <String, Object?>{
          'long_name': 'Texas',
          'short_name': 'TX',
          'types': <String>['administrative_area_level_1', 'political'],
        },
        <String, Object?>{
          'long_name': 'United States',
          'short_name': 'US',
          'types': <String>['country', 'political'],
        },
      ];

      expect(privacyAwareLocationLabel(components), 'Houston, TX');
    });
  });
}
