import 'dart:math';

/// Calculates the distance between two geographic coordinates in miles.
/// [lat1] and [lon1] represent the latitude and longitude of the first point,
/// while [lat2] and [lon2] represent those of the second point.
/// The function uses the Haversine formula to compute the great-circle distance.
double calculateDistance(num lat1, num lon1, num lat2, num lon2) {
  final p = 0.017453292519943295; // pi / 180
  final c = cos;
  final a = 0.5 -
      c((lat2 - lat1) * p) / 2 +
      c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
  // Convert from kilometers to miles (km * 0.621371 = miles)
  return (12742 * asin(sqrt(a))) * 0.621371;
}
