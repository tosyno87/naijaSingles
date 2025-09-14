import 'dart:developer';

/// Service to detect user's region and handle distance unit conversions
class RegionDetectionService {
  // Countries that use miles as primary distance unit
  static const Set<String> _milesCountries = {
    'United States',
    'USA',
    'US',
    'United Kingdom',
    'UK',
    'Liberia',
    'Myanmar',
  };

  /// Detect if user is in a miles-using country based on location data
  static bool isMilesCountry(Map<String, dynamic>? locationData) {
    if (locationData == null) return false;
    
    try {
      final country = locationData['countryName']?.toString() ?? '';
      final countryCode = locationData['countryCode']?.toString() ?? '';
      final placeName = locationData['PlaceName']?.toString() ?? '';
      
      // Check country name
      for (final milesCountry in _milesCountries) {
        if (country.toLowerCase().contains(milesCountry.toLowerCase()) ||
            countryCode.toLowerCase().contains(milesCountry.toLowerCase()) ||
            placeName.toLowerCase().contains(milesCountry.toLowerCase())) {
          return true;
        }
      }
      
      // Check for US state abbreviations in place name
      if (placeName.toLowerCase().contains('usa') ||
          placeName.toLowerCase().contains('united states') ||
          placeName.toLowerCase().contains('america')) {
        return true;
      }
      
      return false;
    } catch (e) {
      log('Error detecting miles country: $e');
      return false; // Default to km for safety
    }
  }

  /// Convert kilometers to miles
  static double kilometersToMiles(double kilometers) {
    return kilometers * 0.621371;
  }

  /// Convert miles to kilometers
  static double milesToKilometers(double miles) {
    return miles * 1.60934;
  }

  /// Format distance with appropriate unit based on region
  static String formatDistance(double distanceKm, Map<String, dynamic>? locationData) {
    try {
      final isMiles = isMilesCountry(locationData);
      
      if (isMiles) {
        final miles = kilometersToMiles(distanceKm);
        return '${miles.round()} miles';
      } else {
        return '${distanceKm.round()} km';
      }
    } catch (e) {
      log('Error formatting distance: $e');
      return '${distanceKm.round()} km'; // Default to km
    }
  }

  /// Get distance unit label based on region
  static String getDistanceUnit(Map<String, dynamic>? locationData) {
    return isMilesCountry(locationData) ? 'miles' : 'km';
  }
}
