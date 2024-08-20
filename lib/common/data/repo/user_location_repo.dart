import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;

import '../../../config/app_config.dart';
import '../../../models/reverse_geocode.dart';

abstract class UserLocationReporistory {
  const UserLocationReporistory._();
  Future<Map?> getLocationCoordinates() async {
    return null;
  }
}

class UserLocationReporistoryImpl implements UserLocationReporistory {
  @override
  Future<Map?> getLocationCoordinates() async {
    loc.Location location = loc.Location();
    try {
      await location.serviceEnabled().then((value) async {
        if (!value) {
          await location.requestService();
        }
      });

      final coordinates = await location.getLocation();

      final reverseGeocode = await getReverseGeocodingData(
          lat: coordinates.latitude!, lng: coordinates.longitude!);

      return reverseGeocode;
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<ReverseGeocode> getReverseGeoding(
      {required double lat, required double lng}) async {
    const geocodeURL = "https://maps.googleapis.com/maps/api/geocode";
    final url =
        Uri.parse("$geocodeURL/json?latlng=$lat,$lng&key=$googleMapsKey");

    final response = await http.get(url);

    log("REVERSE ${response.body}");

    if (response.statusCode == 200) {
      final extractedData = json.decode(response.body) as Map<String, dynamic>;

      if (extractedData.containsKey("results")) {
        final addressDetails = extractedData["results"][0];
        return ReverseGeocode.fromJson(addressDetails);
      } else {
        throw "Couldn't get the address";
      }
    } else {
      throw "Network Error!";
    }
  }

  Future<Map<String, dynamic>> getReverseGeocodingData(
      {required double lat, required double lng}) async {
    const geocodeURL = "https://maps.googleapis.com/maps/api/geocode";
    final url =
        Uri.parse("$geocodeURL/json?latlng=$lat,$lng&key=$googleMapsKey");

    final response = await http.get(url);

    log("REVERSE ${response.body}");

    if (response.statusCode == 200) {
      final extractedData = json.decode(response.body) as Map<String, dynamic>;

      if (extractedData.containsKey("results")) {
        final addressDetails = extractedData["results"][0];
        final List<dynamic> addressComponents =
            addressDetails["address_components"];
        String countryName = "";
        double latitude = lat;
        double longitude = lng;
        String subLocality = '';

        for (var component in addressComponents) {
          final List<String> types = List<String>.from(component["types"]);
          if (types.contains("country")) {
            countryName = component["long_name"];
          }
          if (types.contains("sublocality")) {
            subLocality = component["long_name"];
          }
        }

        Map<String, dynamic> obj = {
          'PlaceName': addressDetails["formatted_address"],
          'countryName': countryName,
          'subLocality': subLocality,
          'latitude': latitude,
          'longitude': longitude,
        };

        return obj;
      } else {
        throw "Couldn't get the address";
      }
    } else {
      throw "Network Error!";
    }
  }
}
