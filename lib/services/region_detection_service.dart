import 'dart:developer';

/// Service to handle distance unit conversions.
/// Afropeep uses miles as the standard distance unit.
class RegionDetectionService {
  static const Set<String> _milesCountries = {
    'United States',
    'USA',
    'US',
    'United Kingdom',
    'UK',
    'Liberia',
    'Myanmar',
  };

  static bool isMilesCountry(Map<String, dynamic>? locationData) {
    if (locationData == null) {
      return true;
    }

    try {
      final country = locationData['countryName']?.toString() ?? '';
      final countryCode = locationData['countryCode']?.toString() ?? '';
      final placeName = locationData['PlaceName']?.toString() ?? '';

      for (final milesCountry in _milesCountries) {
        if (country.toLowerCase().contains(milesCountry.toLowerCase()) ||
            countryCode.toLowerCase().contains(milesCountry.toLowerCase()) ||
            placeName.toLowerCase().contains(milesCountry.toLowerCase())) {
          return true;
        }
      }

      if (placeName.toLowerCase().contains('usa') ||
          placeName.toLowerCase().contains('united states') ||
          placeName.toLowerCase().contains('america')) {
        return true;
      }

      return true;
    } catch (e) {
      log('Error detecting miles country: $e');
      return true;
    }
  }

  static double kilometersToMiles(double kilometers) => kilometers * 0.621371;

  static double milesToKilometers(double miles) => miles * 1.60934;

  static String formatDistance(
    double distanceKm,
    Map<String, dynamic>? locationData,
  ) {
    try {
      final miles = kilometersToMiles(distanceKm);
      return '${miles.round()} miles';
    } catch (e) {
      log('Error formatting distance: $e');
      final miles = kilometersToMiles(distanceKm);
      return '${miles.round()} miles';
    }
  }

  static String getDistanceUnit(Map<String, dynamic>? locationData) => 'miles';
}
