/// Utility class for formatting event locations with fallback handling
/// 
/// This class provides consistent location formatting across the app,
/// handling edge cases like empty locations, placeholders, and malformed data.
class LocationFormatter {
  LocationFormatter._(); // Prevent instantiation

  /// Formats event location with fallback handling
  /// 
  /// Returns:
  /// - "Location TBD" for empty or placeholder locations
  /// - "Online" for online/virtual events
  /// - Original address for valid locations
  static String formatLocation(String displayAddress) {
    final trimmed = displayAddress.trim();

    if (trimmed.isEmpty) {
      return 'Location TBD';
    }

    final lowerAddress = trimmed.toLowerCase();
    
    // Check for online/virtual events first
    if (lowerAddress.contains('online') || lowerAddress.contains('virtual')) {
      return 'Online';
    }
    
    // Check for placeholder patterns or malformed data
    if (lowerAddress.contains('tba') ||
        lowerAddress.contains('tbd') ||
        lowerAddress.contains('to be announced') ||
        lowerAddress.contains('to be determined') ||
        lowerAddress == 'location' ||
        lowerAddress == 'address' ||
        _isMalformedLocation(trimmed)) {
      return 'Location TBD';
    }

    return trimmed;
  }

  /// Checks if a location string appears to be malformed
  /// 
  /// Detects patterns like:
  /// - Very short repeated words (e.g., "ree, re, re")
  /// - Excessive word repetition
  static bool _isMalformedLocation(String address) {
    final words = address.split(',').map((w) => w.trim().toLowerCase()).toList();
    if (words.length > 2) {
      // Check if all words are very short (likely malformed)
      final allShort = words.every((w) => w.length <= 3);
      if (allShort && words.length >= 3) {
        return true;
      }
      // Check for repeated words (more than 50% duplication)
      final uniqueWords = words.toSet();
      if (uniqueWords.length < words.length * 0.5) {
        return true;
      }
    }
    return false;
  }
}

