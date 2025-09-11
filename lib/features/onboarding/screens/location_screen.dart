import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../user/controllers/onboarding_controller.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  String? _currentLocation;
  bool _isLoadingLocation = false;
  bool _locationPermissionDenied = false;
  bool _useZipCode = false;

  // Afropeep MVP theme colors
  static const Color backgroundColor = Colors.white;
  static const Color afropeepGreen = Color(0xFF007A33);
  static const Color cardBackground = Color(0xFFF7E8DA);
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller =
          Provider.of<OnboardingController>(context, listen: false);

      if (controller.locationName != null &&
          controller.locationName!.isNotEmpty) {
        setState(() {
          _currentLocation = controller.locationName;
          _cityController.text = controller.locationName!;
        });
      }
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationPermissionDenied = false;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
          _locationPermissionDenied = true;
        });
        _showLocationServiceDialog();
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
            _locationPermissionDenied = true;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
          _locationPermissionDenied = true;
        });
        _showPermissionDeniedDialog();
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String location = '';

        // Format location based on country
        if (place.country == 'United States') {
          location = '${place.locality}, ${place.administrativeArea}';
        } else if (place.country == 'Canada') {
          location = '${place.locality}, ${place.administrativeArea}';
        } else {
          // For other countries (Europe, etc.)
          location = '${place.locality}, ${place.country}';
        }

        setState(() {
          _currentLocation = location;
          _cityController.text = location;
          _isLoadingLocation = false;
        });

        // Save to controller - CRITICAL FOR DISCOVERY
        final controller =
            Provider.of<OnboardingController>(context, listen: false);
        controller.setLocationName(location);
        controller.setLocationCoordinates(position.latitude, position.longitude);

        print('🔍 LocationScreen: GPS location set to "$location"');
        print('🔍 LocationScreen: Coordinates set to ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationPermissionDenied = true;
      });
      print('Error getting location: $e');
    }
  }

  Future<void> _searchLocationByZip(String zipCode) async {
    if (zipCode.trim().isEmpty) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Get location from zip code
      List<Location> locations = await locationFromAddress(zipCode);

      if (locations.isNotEmpty) {
        Location location = locations[0];

        // Get address details from coordinates
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String locationString = '';

          // Format location based on country
          if (place.country == 'United States') {
            locationString = '${place.locality}, ${place.administrativeArea}';
          } else if (place.country == 'Canada') {
            locationString = '${place.locality}, ${place.administrativeArea}';
          } else {
            locationString = '${place.locality}, ${place.country}';
          }

          setState(() {
            _currentLocation = locationString;
            _cityController.text = locationString;
            _isLoadingLocation = false;
          });

          // Save to controller
          final controller =
              Provider.of<OnboardingController>(context, listen: false);
          controller.setLocationName(locationString);

          print(
              '🔍 LocationScreen: Zip code location set to "$locationString"');
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Could not find location for zip code: $zipCode')),
      );
      print('Error searching by zip: $e');
    }
  }

  void _searchLocationByCity(String city) {
    if (city.trim().isEmpty) return;

    setState(() {
      _currentLocation = city.trim();
    });

    // Save to controller - CRITICAL FOR DISCOVERY
    final controller =
        Provider.of<OnboardingController>(context, listen: false);
    controller.setLocationName(city.trim());
    // Set default coordinates for manual location (Lagos, Nigeria)
    controller.setLocationCoordinates(6.5244, 3.3792);

    print('🔍 LocationScreen: Manual location set to "$city"');
    print('🔍 LocationScreen: Default coordinates set to 6.5244, 3.3792');
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Location Services Disabled',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Please enable location services to use GPS location detection.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: afropeepGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Location Permission Required',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Please enable location permissions in your device settings to use GPS location detection.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: afropeepGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            "Where are you located?",
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textDarkBrown,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "This helps us connect you with people nearby",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: textLightBrown,
            ),
          ),

          const SizedBox(height: 32),

          // GPS Location Button
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
              icon: _isLoadingLocation
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.my_location, color: Colors.white),
              label: Text(
                _isLoadingLocation
                    ? 'Getting Location...'
                    : 'Use My Current Location',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: afropeepGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: GoogleFonts.poppins(
                    color: textLightBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),

          const SizedBox(height: 24),

          // Manual input toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _useZipCode = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_useZipCode ? afropeepGreen : cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            !_useZipCode ? afropeepGreen : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'Enter City',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: !_useZipCode ? Colors.white : textDarkBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _useZipCode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _useZipCode ? afropeepGreen : cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _useZipCode ? afropeepGreen : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      'Enter Zip Code',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: _useZipCode ? Colors.white : textDarkBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Manual input field
          if (!_useZipCode) ...[
            TextField(
              controller: _cityController,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textDarkBrown,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardBackground,
                hintText: "e.g., New York, NY or London, UK",
                hintStyle: GoogleFonts.poppins(
                  color: textLightBrown,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: afropeepGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: IconButton(
                  onPressed: () => _searchLocationByCity(_cityController.text),
                  icon: Icon(Icons.search, color: afropeepGreen),
                ),
              ),
              onSubmitted: _searchLocationByCity,
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  _searchLocationByCity(value);
                }
              },
            ),
          ] else ...[
            TextField(
              controller: _zipController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: textDarkBrown,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: cardBackground,
                hintText: "e.g., 10001 or M5V 3A8",
                hintStyle: GoogleFonts.poppins(
                  color: textLightBrown,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: afropeepGreen, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: IconButton(
                  onPressed: () => _searchLocationByZip(_zipController.text),
                  icon: Icon(Icons.search, color: afropeepGreen),
                ),
              ),
              onSubmitted: _searchLocationByZip,
            ),
          ],

          const SizedBox(height: 24),

          // Current location display
          if (_currentLocation != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: afropeepGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: afropeepGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: afropeepGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Location',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: textLightBrown,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _currentLocation!,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: textDarkBrown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: afropeepGreen,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Privacy note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: afropeepGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: afropeepGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: afropeepGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Your location helps us show you people nearby. We only show your city, never your exact location.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textDarkBrown,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
