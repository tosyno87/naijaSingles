import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;

import '../../../config/app_config.dart';
import '../../../models/reverse_geocode.dart';

abstract class UserLocationReporistory {
  const UserLocationReporistory._();
  Future<Map?> getLocationCoordinates();
  Future<Map> getDefaultLocation();
}

class UserLocationReporistoryImpl implements UserLocationReporistory {
  @override
  Future<Map?> getLocationCoordinates() async {
    loc.Location location = loc.Location();
    try {
      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        try {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) {
            log("Location services are disabled and user declined to enable");
            return getDefaultLocation();
          }
        } catch (e) {
          log("Error requesting location service: ${e.toString()}");
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
            log("Location permission denied");
            return getDefaultLocation();
          }
        }
      } catch (e) {
        log("Error checking location permission: ${e.toString()}");
        return getDefaultLocation();
      }

      // Get location with timeout
      loc.LocationData? coordinates;
      try {
        coordinates = await Future.delayed(const Duration(seconds: 10), () async {
          try {
            return await location.getLocation();
          } catch (e) {
            log("Error getting location: ${e.toString()}");
            return null;
          }
        });
        
        if (coordinates == null) {
          log("Location request timed out");
          return getDefaultLocation();
        }
      } catch (e) {
        log("Error getting location with timeout: ${e.toString()}");
        return getDefaultLocation();
      }
      
      if (coordinates.latitude == null || coordinates.longitude == null) {
        log("Could not get coordinates - null values");
        return getDefaultLocation();
      }

      try {
        final reverseGeocode = await getReverseGeocodingData(
            lat: coordinates.latitude!, lng: coordinates.longitude!);
        return reverseGeocode;
      } catch (e) {
        log("Geocoding error: ${e.toString()}");
        // Return basic location data even if geocoding fails
        return {
          'PlaceName': "Unknown Location",
          'countryName': "",
          'subLocality': "",
          'latitude': coordinates.latitude,
          'longitude': coordinates.longitude,
        };
      }
    } catch (e) {
      log("Location error: ${e.toString()}");
      return getDefaultLocation();
    }
  }

  @override
  Future<Map> getDefaultLocation() async {
    // Default to Lagos, Nigeria coordinates
    log("Using default location (Lagos, Nigeria)");
    return {
      'PlaceName': "Lagos, Nigeria",
      'countryName': "Nigeria",
      'subLocality': "Lagos",
      'latitude': 6.5244,
      'longitude': 3.3792,
    };
  }

  Future<ReverseGeocode> getReverseGeoding(
      {required double lat, required double lng}) async {
    try {
      const geocodeURL = "https://maps.googleapis.com/maps/api/geocode";
      final url =
          Uri.parse("$geocodeURL/json?latlng=$lat,$lng&key=$googleMapsKey");

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw "Request timed out";
        },
      );

      log("REVERSE ${response.body}");

      if (response.statusCode == 200) {
        final extractedData = json.decode(response.body) as Map<String, dynamic>;

        if (extractedData.containsKey("results") && 
            extractedData["results"] is List && 
            extractedData["results"].isNotEmpty) {
          final addressDetails = extractedData["results"][0];
          return ReverseGeocode.fromJson(addressDetails);
        } else {
          throw "Couldn't get the address from response";
        }
      } else {
        throw "Network Error! Status code: ${response.statusCode}";
      }
    } catch (e) {
      log("Reverse geocoding error: ${e.toString()}");
      throw "Failed to get address: ${e.toString()}";
    }
  }

  Future<Map<String, dynamic>> getReverseGeocodingData(
      {required double lat, required double lng}) async {
    try {
      const geocodeURL = "https://maps.googleapis.com/maps/api/geocode";
      final url =
          Uri.parse("$geocodeURL/json?latlng=$lat,$lng&key=$googleMapsKey");

      final response = await http.get(url).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw "Request timed out";
        },
      );

      log("REVERSE ${response.body}");

      if (response.statusCode == 200) {
        final extractedData = json.decode(response.body) as Map<String, dynamic>;

        // Check if the API returned an error
        if (extractedData.containsKey("error_message")) {
          log("Google Maps API error: ${extractedData["error_message"]}");
          throw "Google Maps API error: ${extractedData["error_message"]}";
        }

        if (extractedData.containsKey("results") && 
            extractedData["results"] is List && 
            extractedData["results"].isNotEmpty) {
          final addressDetails = extractedData["results"][0];
          final List<dynamic> addressComponents =
              addressDetails["address_components"] ?? [];
          String countryName = "";
          double latitude = lat;
          double longitude = lng;
          String subLocality = '';

          for (var component in addressComponents) {
            final List<String> types = List<String>.from(component["types"] ?? []);
            if (types.contains("country")) {
              countryName = component["long_name"] ?? "";
            }
            if (types.contains("sublocality")) {
              subLocality = component["long_name"] ?? "";
            }
          }

          Map<String, dynamic> obj = {
            'PlaceName': addressDetails["formatted_address"] ?? "Unknown Location",
            'countryName': countryName,
            'subLocality': subLocality,
            'latitude': latitude,
            'longitude': longitude,
          };

          return obj;
        } else {
          log("No results in geocoding response");
          // Return basic location data
          return {
            'PlaceName': "Unknown Location",
            'countryName': "",
            'subLocality': "",
            'latitude': lat,
            'longitude': lng,
          };
        }
      } else {
        log("Geocoding API error: ${response.statusCode}");
        // Return basic location data
        return {
          'PlaceName': "Unknown Location",
          'countryName': "",
          'subLocality': "",
          'latitude': lat,
          'longitude': lng,
        };
      }
    } catch (e) {
      log("Geocoding error: ${e.toString()}");
      // Return basic location data
      return {
        'PlaceName': "Unknown Location",
        'countryName': "",
        'subLocality': "",
        'latitude': lat,
        'longitude': lng,
      };
    }
  }
}
