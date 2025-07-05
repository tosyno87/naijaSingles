import 'dart:math';

/// Location precision levels for privacy control
enum LocationPrecision {
  high,   // ~0.6 miles radius (GeoHash precision 7)
  medium, // ~3 miles radius (GeoHash precision 6) 
  low     // ~15 miles radius (GeoHash precision 5)
}

/// Service for handling location privacy with GeoHash
class LocationPrivacyService {
  
  /// Convert lat/lng to privacy-aware location data
  static Map<String, dynamic> createPrivateLocation({
    required double latitude,
    required double longitude,
    required LocationPrecision precision,
    required String city,
    required String state,
    required String country,
  }) {
    final geoHash = _generateGeoHash(latitude, longitude, precision);
    
    return {
      'city': city,
      'state': state,
      'country': country,
      'region': '$city, ${_getCountryCode(country)}',
      'geoHash': geoHash,
      'precision': precision.name,
      'approximateRadius': _getApproximateRadius(precision),
      'displayLocation': _formatDisplayLocation(city, state, country),
      // NO exact coordinates stored in public data
    };
  }
  
  /// Generate GeoHash based on precision level (public method)
  static String generateGeoHash(double lat, double lng, LocationPrecision precision) {
    return _generateGeoHash(lat, lng, precision);
  }
  
  /// Decode GeoHash to approximate coordinates (public method)
  static Map<String, double> decodeGeoHash(String geoHash) {
    return _decodeGeoHash(geoHash);
  }

  /// Generate GeoHash based on precision level
  static String _generateGeoHash(double lat, double lng, LocationPrecision precision) {
    int precisionLevel;
    switch (precision) {
      case LocationPrecision.high:
        precisionLevel = 7; // ~0.6 miles accuracy
        break;
      case LocationPrecision.medium:
        precisionLevel = 6; // ~3 miles accuracy
        break;
      case LocationPrecision.low:
        precisionLevel = 5; // ~15 miles accuracy
        break;
    }
    
    return _encodeGeoHash(lat, lng, precisionLevel);
  }
  
  /// Simple GeoHash encoding implementation
  static String _encodeGeoHash(double lat, double lng, int precision) {
    const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    
    String geoHash = '';
    int bits = 0;
    int bit = 0;
    bool evenBit = true;
    
    while (geoHash.length < precision) {
      if (evenBit) {
        // longitude
        double mid = (lngMin + lngMax) / 2;
        if (lng >= mid) {
          bit = (bit << 1) + 1;
          lngMin = mid;
        } else {
          bit = bit << 1;
          lngMax = mid;
        }
      } else {
        // latitude
        double mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          bit = (bit << 1) + 1;
          latMin = mid;
        } else {
          bit = bit << 1;
          latMax = mid;
        }
      }
      
      evenBit = !evenBit;
      bits++;
      
      if (bits == 5) {
        geoHash += base32[bit];
        bits = 0;
        bit = 0;
      }
    }
    
    return geoHash;
  }
  
  /// Calculate distance between two GeoHashes in miles
  static double calculateDistanceInMiles(String geoHash1, String geoHash2) {
    final coords1 = _decodeGeoHash(geoHash1);
    final coords2 = _decodeGeoHash(geoHash2);
    
    return _haversineDistanceInMiles(
      coords1['lat']!, coords1['lng']!,
      coords2['lat']!, coords2['lng']!
    );
  }
  
  /// Decode GeoHash to approximate coordinates
  static Map<String, double> _decodeGeoHash(String geoHash) {
    const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    
    double latMin = -90.0, latMax = 90.0;
    double lngMin = -180.0, lngMax = 180.0;
    
    bool evenBit = true;
    
    for (int i = 0; i < geoHash.length; i++) {
      int cd = base32.indexOf(geoHash[i]);
      
      for (int j = 4; j >= 0; j--) {
        int bit = (cd >> j) & 1;
        
        if (evenBit) {
          // longitude
          double mid = (lngMin + lngMax) / 2;
          if (bit == 1) {
            lngMin = mid;
          } else {
            lngMax = mid;
          }
        } else {
          // latitude
          double mid = (latMin + latMax) / 2;
          if (bit == 1) {
            latMin = mid;
          } else {
            latMax = mid;
          }
        }
        
        evenBit = !evenBit;
      }
    }
    
    return {
      'lat': (latMin + latMax) / 2,
      'lng': (lngMin + lngMax) / 2,
    };
  }
  
  /// Calculate distance using Haversine formula in miles
  static double _haversineDistanceInMiles(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadiusMiles = 3959; // miles (vs 6371 km)
    
    double dLat = _toRadians(lat2 - lat1);
    double dLng = _toRadians(lng2 - lng1);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusMiles * c;
  }
  
  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }
  
  /// Get approximate radius for precision level in miles
  static int _getApproximateRadius(LocationPrecision precision) {
    switch (precision) {
      case LocationPrecision.high:
        return 1; // ~0.6 miles (rounded up for display)
      case LocationPrecision.medium:
        return 3; // ~3 miles
      case LocationPrecision.low:
        return 15; // ~15 miles
    }
  }
  
  /// Get country code for region display
  static String _getCountryCode(String country) {
    final countryMap = {
      'Nigeria': 'NG',
      'Ghana': 'GH',
      'Kenya': 'KE',
      'South Africa': 'ZA',
      'Egypt': 'EG',
      'Morocco': 'MA',
      'Ethiopia': 'ET',
      'Uganda': 'UG',
      'Tanzania': 'TZ',
      'Algeria': 'DZ',
      'Cameroon': 'CM',
      'Ivory Coast': 'CI',
      'Angola': 'AO',
      'Sudan': 'SD',
      'Mozambique': 'MZ',
    };
    
    return countryMap[country] ?? country.substring(0, 2).toUpperCase();
  }
  
  /// Format display location
  static String _formatDisplayLocation(String city, String state, String country) {
    if (city.isNotEmpty && state.isNotEmpty) {
      return '$city, $state';
    } else if (city.isNotEmpty) {
      return '$city, ${_getCountryCode(country)}';
    } else {
      return '${_getCountryCode(country)}';
    }
  }
  
  /// Get users within radius using GeoHash (radius in miles)
  static List<String> getGeoHashesInRadius(String centerGeoHash, double radiusMiles) {
    // Get neighboring GeoHashes for radius search
    List<String> neighbors = [];
    
    // Add center
    neighbors.add(centerGeoHash);
    
    // Add direct neighbors (8 directions)
    neighbors.addAll(_getNeighbors(centerGeoHash));
    
    // For larger radius, add second-level neighbors
    if (radiusMiles > 3) {
      for (String neighbor in List.from(neighbors)) {
        neighbors.addAll(_getNeighbors(neighbor));
      }
    }
    
    return neighbors.toSet().toList(); // Remove duplicates
  }
  
  /// Get neighboring GeoHashes
  static List<String> _getNeighbors(String geoHash) {
    // Simplified neighbor calculation
    // In production, use a proper GeoHash library
    List<String> neighbors = [];
    
    if (geoHash.length > 1) {
      String base = geoHash.substring(0, geoHash.length - 1);
      String lastChar = geoHash.substring(geoHash.length - 1);
      
      const String base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
      int index = base32.indexOf(lastChar);
      
      // Add adjacent characters
      if (index > 0) neighbors.add(base + base32[index - 1]);
      if (index < base32.length - 1) neighbors.add(base + base32[index + 1]);
    }
    
    return neighbors;
  }
  
  /// Convert LocationPrecision enum to string
  static String precisionToString(LocationPrecision precision) {
    switch (precision) {
      case LocationPrecision.high:
        return 'High (~1 mile)';
      case LocationPrecision.medium:
        return 'Medium (~3 miles)';
      case LocationPrecision.low:
        return 'Low (~15 miles)';
    }
  }
  
  /// Convert string to LocationPrecision enum
  static LocationPrecision stringToPrecision(String precision) {
    switch (precision.toLowerCase()) {
      case 'high':
        return LocationPrecision.high;
      case 'medium':
        return LocationPrecision.medium;
      case 'low':
        return LocationPrecision.low;
      default:
        return LocationPrecision.medium; // Default
    }
  }
  
  /// Format distance for display
  static String formatDistance(double miles) {
    if (miles < 1) {
      return 'Less than 1 mile away';
    } else if (miles < 2) {
      return '1 mile away';
    } else if (miles < 10) {
      return '${miles.round()} miles away';
    } else {
      return '${miles.round()}+ miles away';
    }
  }
  
  /// Convert miles to kilometers (for international users)
  static double milesToKilometers(double miles) {
    return miles * 1.60934;
  }
  
  /// Convert kilometers to miles
  static double kilometersToMiles(double kilometers) {
    return kilometers * 0.621371;
  }
}
