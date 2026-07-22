import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;

import '../../../config/app_config.dart';
import '../../../models/reverse_geocode.dart';

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.description,
    required this.placeId,
  });

  final String description;
  final String placeId;
}

class PlaceAutocompleteResult {
  const PlaceAutocompleteResult({
    required this.suggestions,
    this.status = 'OK',
    this.errorMessage,
  });

  final List<PlaceSuggestion> suggestions;
  final String status;
  final String? errorMessage;

  bool get isDenied => status == 'REQUEST_DENIED';
  bool get isOk => status == 'OK' || status == 'ZERO_RESULTS';
}

/// Dating-app safe label: city/locality + region, never street/house number.
String privacyAwareLocationLabel(List<dynamic> addressComponents) {
  String locality = '';
  String adminArea = '';
  String adminAreaShort = '';
  String country = '';
  String countryShort = '';
  String neighborhood = '';

  for (final Object? component in addressComponents) {
    if (component is! Map) continue;
    final Map<String, dynamic> row = Map<String, dynamic>.from(component);
    final List<String> types = List<String>.from(
      (row['types'] as List?) ?? const <dynamic>[],
    );
    final String longName = row['long_name']?.toString() ?? '';
    final String shortName = row['short_name']?.toString() ?? '';
    if (types.contains('locality') || types.contains('postal_town')) {
      if (locality.isEmpty) locality = longName;
    } else if (types.contains('sublocality') ||
        types.contains('sublocality_level_1') ||
        types.contains('neighborhood')) {
      if (neighborhood.isEmpty) neighborhood = longName;
    } else if (types.contains('administrative_area_level_1')) {
      adminArea = longName;
      adminAreaShort = shortName;
    } else if (types.contains('country')) {
      country = longName;
      countryShort = shortName;
    }
  }

  final String city = locality.isNotEmpty ? locality : neighborhood;
  final bool isUsOrCa =
      countryShort == 'US' ||
      countryShort == 'CA' ||
      country == 'United States' ||
      country == 'Canada';

  if (city.isNotEmpty && adminAreaShort.isNotEmpty && isUsOrCa) {
    return '$city, $adminAreaShort';
  }
  if (city.isNotEmpty && adminArea.isNotEmpty) {
    return '$city, $adminArea';
  }
  if (city.isNotEmpty && country.isNotEmpty) {
    return '$city, $country';
  }
  if (city.isNotEmpty) return city;
  if (adminArea.isNotEmpty && country.isNotEmpty) {
    return '$adminArea, $country';
  }
  if (country.isNotEmpty) return country;
  return 'Unknown Location';
}

/// Prefer city from *any* reverse-geocode result's components.
/// Street results usually include `locality`; state-level results do not.
String privacyAwareLocationLabelFromResults(List<dynamic> results) {
  final List<dynamic> merged = <dynamic>[];
  for (final Object? item in results) {
    if (item is! Map) continue;
    final Object? components = item['address_components'];
    if (components is List) {
      merged.addAll(components);
    }
  }
  return privacyAwareLocationLabel(merged);
}

bool _resultHasType(Map<String, dynamic> result, Set<String> wanted) {
  final Object? types = result['types'];
  if (types is! List) return false;
  for (final Object? t in types) {
    if (wanted.contains(t?.toString())) return true;
  }
  return false;
}

/// City/locality geometry only — never snap to state/country.
Map<String, dynamic>? pickLocalityGeocodeResult(List<dynamic> results) {
  const Set<String> preferred = <String>{
    'locality',
    'postal_town',
  };
  for (final Object? item in results) {
    if (item is! Map) continue;
    final Map<String, dynamic> row = Map<String, dynamic>.from(item);
    if (_resultHasType(row, preferred)) return row;
  }
  return null;
}

const Set<String> _coarsePlaceTypes = <String>{
  'locality',
  'postal_town',
  'administrative_area_level_1',
  'administrative_area_level_2',
  'administrative_area_level_3',
  'country',
  'political',
  'geocode',
};

const Set<String> _preciseComponentTypes = <String>{
  'street_number',
  'route',
  'premise',
  'subpremise',
  'plus_code',
  'neighborhood',
  'sublocality',
  'sublocality_level_1',
  'point_of_interest',
  'establishment',
  'park',
  'airport',
  'university',
  'shopping_mall',
  'store',
};

/// True when Place Details is already city/region-level (no POI/street pin).
bool _isAlreadyCoarsePlace(
  Map<String, dynamic> place,
  List<dynamic> components,
) {
  final Object? typesRaw = place['types'];
  if (typesRaw is List && typesRaw.isNotEmpty) {
    final bool allCoarse = typesRaw.every(
      (Object? t) => _coarsePlaceTypes.contains(t?.toString()),
    );
    if (allCoarse) return true;
  }

  for (final Object? component in components) {
    if (component is! Map) continue;
    final List<String> types = List<String>.from(
      (component['types'] as List?) ?? const <dynamic>[],
    );
    for (final String type in types) {
      if (_preciseComponentTypes.contains(type)) return false;
    }
  }
  // No precise components and no fine place types → treat as coarse.
  return true;
}

abstract class UserLocationReporistory {
  const UserLocationReporistory._();
  Future<Map?> getLocationCoordinates();
  Future<Map> getDefaultLocation();
}

class UserLocationReporistoryImpl implements UserLocationReporistory {
  @override
  Future<Map?> getLocationCoordinates() async {
    final loc.Location location = loc.Location();
    try {
      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        try {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) {
            log('Location services are disabled and user declined to enable');
            return getDefaultLocation();
          }
        } on Object catch (e) {
          log('Error requesting location service: ${e.toString()}');
          return getDefaultLocation();
        }
      }

      // Check location permission
      loc.PermissionStatus permissionStatus;
      try {
        permissionStatus = await location.hasPermission();
        if (permissionStatus == loc.PermissionStatus.denied) {
          permissionStatus = await location.requestPermission();
          if (permissionStatus != loc.PermissionStatus.granted) {
            log('Location permission denied');
            return getDefaultLocation();
          }
        }
      } on Object catch (e) {
        log('Error checking location permission: ${e.toString()}');
        return getDefaultLocation();
      }

      // Get location with timeout
      loc.LocationData? coordinates;
      try {
        coordinates =
            await location.getLocation().timeout(const Duration(seconds: 10));
      } on Object catch (e) {
        log('Error getting location with timeout: ${e.toString()}');
        return getDefaultLocation();
      }

      if (coordinates.latitude == null || coordinates.longitude == null) {
        log('Could not get coordinates - null values');
        return getDefaultLocation();
      }

      try {
        final reverseGeocode = await getReverseGeocodingData(
          lat: coordinates.latitude!,
          lng: coordinates.longitude!,
        );
        return reverseGeocode;
      } on Object catch (e) {
        log('Geocoding error: ${e.toString()}');
        // Return basic location data even if geocoding fails
        return {
          'PlaceName': 'Unknown Location',
          'countryName': '',
          'subLocality': '',
          'latitude': coordinates.latitude,
          'longitude': coordinates.longitude,
        };
      }
    } on Object catch (e) {
      log('Location error: ${e.toString()}');
      return getDefaultLocation();
    }
  }

  @override
  Future<Map> getDefaultLocation() async {
    // Default to Lagos, Nigeria coordinates
    log('Using default location (Lagos, Nigeria)');
    return {
      'PlaceName': 'Lagos, Nigeria',
      'countryName': 'Nigeria',
      'subLocality': 'Lagos',
      'latitude': 6.5244,
      'longitude': 3.3792,
    };
  }

  Future<ReverseGeocode> getReverseGeoding({
    required double lat,
    required double lng,
  }) async {
    try {
      if (googleMapsPlacesHttpKey.isEmpty) {
        throw Exception(
          'Google Maps API key is empty. Set GOOGLE_MAPS_WEB_API_KEY.',
        );
      }
      const geocodeURL = 'https://maps.googleapis.com/maps/api/geocode';
      final url =
          Uri.parse('$geocodeURL/json?latlng=$lat,$lng&key=$googleMapsPlacesHttpKey');

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Network Error! Status code: ${response.statusCode}');
      }

      final Object? decoded = json.decode(response.body);
      if (decoded is! Map) {
        throw Exception('Unexpected geocode response shape');
      }
      final Map<String, dynamic> extractedData =
          Map<String, dynamic>.from(decoded);

      final Object? errorMessage = extractedData['error_message'];
      if (errorMessage != null) {
        throw Exception('Google Maps API error: $errorMessage');
      }

      final Object? results = extractedData['results'];
      if (results is! List || results.isEmpty) {
        throw Exception("Couldn't get the address from response");
      }
      final String label = privacyAwareLocationLabelFromResults(results);
      final Map<String, dynamic>? locality = pickLocalityGeocodeResult(results);
      final Object? first = results.first;
      final String placeId = locality?['place_id']?.toString() ??
          (first is Map ? first['place_id']?.toString() ?? '' : '');
      return ReverseGeocode(
        placeId: placeId,
        formattedAddress: label,
      );
    } on Object catch (e) {
      log('Reverse geocoding error: ${e.toString()}');
      throw Exception('Failed to get address: ${e.toString()}');
    }
  }

  /// Forward-geocode a free-text address (Places Details fallback).
  Future<Map<String, dynamic>?> geocodeAddress(String address) async {
    if (address.trim().isEmpty || googleMapsPlacesHttpKey.isEmpty) return null;
    try {
      const geocodeURL = 'https://maps.googleapis.com/maps/api/geocode';
      final url = Uri.parse(
        '$geocodeURL/json?address=${Uri.encodeComponent(address)}&key=$googleMapsPlacesHttpKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        log('Forward geocode HTTP ${response.statusCode}');
        return null;
      }
      final Object? decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
      final String status = data['status']?.toString() ?? '';
      if (status != 'OK') {
        log('Forward geocode status=$status error=${data['error_message']}');
        return null;
      }
      final Object? results = data['results'];
      if (results is! List || results.isEmpty) return null;
      final String label = privacyAwareLocationLabelFromResults(results);
      final Map<String, dynamic>? locality = pickLocalityGeocodeResult(results);
      final Map<String, dynamic> item = locality ??
          (results.first is Map
              ? Map<String, dynamic>.from(results.first as Map)
              : <String, dynamic>{});
      final Object? geometry = item['geometry'];
      if (geometry is! Map) return null;
      final Object? location = geometry['location'];
      if (location is! Map) return null;
      final double? lat = (location['lat'] as num?)?.toDouble();
      final double? lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return {
        'latitude': lat,
        'longitude': lng,
        'PlaceName': label,
      };
    } on Object catch (e) {
      log('Forward geocode error: $e');
      return null;
    }
  }

  /// Places Autocomplete with safe JSON parsing (avoids flaky package casts).
  Future<PlaceAutocompleteResult> autocompletePlaces(String input) async {
    if (input.trim().length < 2 || googleMapsPlacesHttpKey.isEmpty) {
      return const PlaceAutocompleteResult(
        suggestions: <PlaceSuggestion>[],
        status: 'MISSING_KEY',
        errorMessage: 'Google Places HTTP key is not configured',
      );
    }
    try {
      final Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(input.trim())}'
        '&language=en'
        '&key=$googleMapsPlacesHttpKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        log('Places autocomplete HTTP ${response.statusCode}');
        return PlaceAutocompleteResult(
          suggestions: const <PlaceSuggestion>[],
          status: 'HTTP_${response.statusCode}',
          errorMessage: 'Network error ${response.statusCode}',
        );
      }
      final Object? decoded = json.decode(response.body);
      if (decoded is! Map) {
        return const PlaceAutocompleteResult(
          suggestions: <PlaceSuggestion>[],
          status: 'BAD_JSON',
        );
      }
      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
      final String status = data['status']?.toString() ?? '';
      final String? apiError = data['error_message']?.toString();
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        log('Places autocomplete status=$status error=$apiError');
        return PlaceAutocompleteResult(
          suggestions: const <PlaceSuggestion>[],
          status: status.isEmpty ? 'UNKNOWN' : status,
          errorMessage: apiError,
        );
      }
      final Object? predictions = data['predictions'];
      if (predictions is! List) {
        return PlaceAutocompleteResult(
          suggestions: const <PlaceSuggestion>[],
          status: status,
        );
      }
      final List<PlaceSuggestion> out = <PlaceSuggestion>[];
      for (final Object? item in predictions) {
        if (item is! Map) continue;
        final Map<String, dynamic> row = Map<String, dynamic>.from(item);
        final String description = row['description']?.toString() ?? '';
        final String placeId = row['place_id']?.toString() ?? '';
        if (description.isEmpty) continue;
        out.add(PlaceSuggestion(description: description, placeId: placeId));
      }
      return PlaceAutocompleteResult(suggestions: out, status: status);
    } on Object catch (e) {
      log('Places autocomplete error: $e');
      return PlaceAutocompleteResult(
        suggestions: const <PlaceSuggestion>[],
        status: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  /// Place Details geometry with safe JSON parsing.
  Future<Map<String, dynamic>?> placeDetailsLatLng(String placeId) async {
    if (placeId.isEmpty || googleMapsPlacesHttpKey.isEmpty) return null;
    try {
      final Uri url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${Uri.encodeComponent(placeId)}'
        '&fields=geometry,formatted_address,address_component'
        '&key=$googleMapsPlacesHttpKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final Object? decoded = json.decode(response.body);
      if (decoded is! Map) return null;
      final Map<String, dynamic> data = Map<String, dynamic>.from(decoded);
      final String status = data['status']?.toString() ?? '';
      if (status != 'OK') {
        log('Place details status=$status error=${data['error_message']}');
        return null;
      }
      final Object? result = data['result'];
      if (result is! Map) return null;
      final Map<String, dynamic> place = Map<String, dynamic>.from(result);
      final Object? geometry = place['geometry'];
      if (geometry is! Map) return null;
      final Object? location = geometry['location'];
      if (location is! Map) return null;
      final double? lat = (location['lat'] as num?)?.toDouble();
      final double? lng = (location['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      final List<dynamic> components = place['address_components'] is List
          ? place['address_components'] as List<dynamic>
          : <dynamic>[];
      final String label = privacyAwareLocationLabel(components);

      // Always snap precise Places (street, POI, premise, park, etc.) to the
      // privacy label's city/region center — not only street_number/route.
      if (label != 'Unknown Location' &&
          !_isAlreadyCoarsePlace(place, components)) {
        final Map<String, dynamic>? city = await geocodeAddress(label);
        if (city != null) {
          return city;
        }
      }

      return {
        'latitude': lat,
        'longitude': lng,
        'PlaceName': label == 'Unknown Location'
            ? place['formatted_address']?.toString()
            : label,
      };
    } on Object catch (e) {
      log('Place details error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getReverseGeocodingData({
    required double lat,
    required double lng,
  }) async {
    Map<String, dynamic> fallback() => {
          'PlaceName': 'Unknown Location',
          'countryName': '',
          'subLocality': '',
          'latitude': lat,
          'longitude': lng,
        };

    try {
      if (googleMapsPlacesHttpKey.isEmpty) {
        log('Geocoding skipped: empty Google Maps API key');
        return fallback();
      }
      const geocodeURL = 'https://maps.googleapis.com/maps/api/geocode';
      final url =
          Uri.parse('$geocodeURL/json?latlng=$lat,$lng&key=$googleMapsPlacesHttpKey');

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode != 200) {
        log('Geocoding API error: ${response.statusCode}');
        return fallback();
      }

      final Object? decoded = json.decode(response.body);
      if (decoded is! Map) {
        log('Geocoding response was not a JSON object');
        return fallback();
      }
      final Map<String, dynamic> extractedData =
          Map<String, dynamic>.from(decoded);

      if (extractedData.containsKey('error_message')) {
        log("Google Maps API error: ${extractedData["error_message"]}");
        return fallback();
      }

      final Object? results = extractedData['results'];
      if (results is! List || results.isEmpty) {
        log('No results in geocoding response');
        return fallback();
      }
      final String label = privacyAwareLocationLabelFromResults(results);
      final Map<String, dynamic>? localityResult =
          pickLocalityGeocodeResult(results);

      String countryName = '';
      String subLocality = '';
      for (final Object? item in results) {
        if (item is! Map) continue;
        final Object? comps = item['address_components'];
        if (comps is! List) continue;
        for (final Object? component in comps) {
          if (component is! Map) continue;
          final List<String> types = List<String>.from(
            (component['types'] as List?) ?? const <dynamic>[],
          );
          if (types.contains('country') && countryName.isEmpty) {
            countryName = component['long_name']?.toString() ?? '';
          }
          if ((types.contains('locality') || types.contains('postal_town')) &&
              subLocality.isEmpty) {
            subLocality = component['long_name']?.toString() ?? '';
          }
        }
      }

      // Keep GPS coords unless we have a true city/locality center.
      double outLat = lat;
      double outLng = lng;
      final Object? geometry = localityResult?['geometry'];
      if (geometry is Map) {
        final Object? location = geometry['location'];
        if (location is Map) {
          final double? gLat = (location['lat'] as num?)?.toDouble();
          final double? gLng = (location['lng'] as num?)?.toDouble();
          if (gLat != null && gLng != null) {
            outLat = gLat;
            outLng = gLng;
          }
        }
      }

      return {
        'PlaceName': label,
        'countryName': countryName,
        'subLocality': subLocality,
        'latitude': outLat,
        'longitude': outLng,
      };
    } on Object catch (e) {
      log('Geocoding error: ${e.toString()}');
      return fallback();
    }
  }
}
