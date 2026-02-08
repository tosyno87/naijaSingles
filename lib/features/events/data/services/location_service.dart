import 'dart:developer';
import 'package:geolocator/geolocator.dart';

class LocationService {
  factory LocationService() => _instance;
  LocationService._internal();
  static final LocationService _instance = LocationService._internal();

  Position? _currentPosition;
  DateTime? _lastLocationUpdate;
  static const Duration _locationCacheTimeout = Duration(minutes: 5);

  /// Get the user's current location
  Future<Position?> getCurrentLocation({bool forceRefresh = false}) async {
    try {
      // Check if we have a cached location that's still valid
      if (!forceRefresh &&
          _currentPosition != null &&
          _lastLocationUpdate != null &&
          DateTime.now().difference(_lastLocationUpdate!) <
              _locationCacheTimeout) {
        log(
          '📍 Using cached location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
          name: 'LocationService',
        );
        return _currentPosition;
      }

      // Check location permissions
      final permissionStatus = await _checkLocationPermissions();
      if (!permissionStatus) {
        log('❌ Location permission denied', name: 'LocationService');
        return null;
      }

      // Get current position
      log('📍 Getting current location...', name: 'LocationService');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _lastLocationUpdate = DateTime.now();

      log(
        '📍 Location obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
        name: 'LocationService',
      );
      return _currentPosition;
    } catch (e) {
      log('❌ Error getting location: $e', name: 'LocationService');
      return null;
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermissions() async {
    try {
      // Check if location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        log('❌ Location services are disabled', name: 'LocationService');
        return false;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          log('❌ Location permission denied by user', name: 'LocationService');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        log(
          '❌ Location permission permanently denied',
          name: 'LocationService',
        );
        return false;
      }

      log('✅ Location permission granted', name: 'LocationService');
      return true;
    } catch (e) {
      log('❌ Error checking location permissions: $e', name: 'LocationService');
      return false;
    }
  }

  /// Calculate distance between two coordinates in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  /// Calculate distance between user location and event location
  static double? calculateDistanceToEvent(
    Position? userLocation,
    double? eventLat,
    double? eventLon,
  ) {
    if (userLocation == null || eventLat == null || eventLon == null) {
      return null;
    }

    return calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      eventLat,
      eventLon,
    );
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)}km';
    } else {
      return '${distanceKm.round()}km';
    }
  }

  /// Clear cached location
  void clearLocationCache() {
    _currentPosition = null;
    _lastLocationUpdate = null;
    log('🗑️ Location cache cleared', name: 'LocationService');
  }

  /// Get last known location (cached)
  Position? getLastKnownLocation() => _currentPosition;
}
