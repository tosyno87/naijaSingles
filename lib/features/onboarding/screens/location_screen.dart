import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/utils/app_logger.dart';
import '../bloc/onboarding_bloc.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? _currentLocation;
  bool _isLoadingLocation = false;
  bool _locationPermissionDenied = false;

  // Afropeep MVP theme colors
  static const Color afropeepGreen = Color(0xFF008037); // MVP green
  static const Color textDarkBrown = Color(0xFF3A1D0F);
  static const Color textLightBrown = Color(0xFF8B6C59);

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;

      if (data?.locationName != null &&
          data!.locationName!.isNotEmpty) {
        setState(() {
          _currentLocation = data.locationName;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationPermissionDenied = false;
    });

    try {
      // Check if location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
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
          _isLoadingLocation = false;
        });

        if (!mounted) return;

        // Save to bloc - CRITICAL FOR DISCOVERY
        context.read<OnboardingBloc>().add(
              OnboardingLocationUpdated(
                position.latitude,
                position.longitude,
                location,
              ),
            );

        AppLogger.info('🔍 LocationScreen: GPS location set to "$location"');
        AppLogger.info(
          '🔍 LocationScreen: Coordinates set to ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationPermissionDenied = true;
      });
      AppLogger.error('Error getting location', error: e);
    }
  }

  void _showLocationServiceDialog() {
    unawaited(showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Location Services Disabled',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Location is required to find matches nearby. Please enable location services in your device settings.',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: textDarkBrown,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: textLightBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final opened = await Geolocator.openLocationSettings();
              if (!opened) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enable location services manually in your device settings',
                      style: GoogleFonts.montserrat(),
                    ),
                    backgroundColor: afropeepGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: afropeepGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  void _showPermissionDeniedDialog() {
    unawaited(showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Location Permission Required',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Location is required to find matches nearby. Please enable location permissions in your device settings to continue.',
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: textDarkBrown,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: textLightBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final opened = await Geolocator.openLocationSettings();
              if (!opened) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enable location permissions manually in your device settings',
                      style: GoogleFonts.montserrat(),
                    ),
                    backgroundColor: afropeepGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: afropeepGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Where are you located?',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textDarkBrown,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'This helps us connect you with people nearby',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textLightBrown,
              ),
            ),

            const SizedBox(height: 32),

            // GPS Location Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.my_location, color: Colors.white),
                label: Text(
                  _isLoadingLocation
                      ? 'Getting Location...'
                      : 'Use My Current Location',
                  style: GoogleFonts.montserrat(
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

            const SizedBox(height: 32),

            // Current location display
            if (_currentLocation != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: afropeepGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: afropeepGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
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
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              color: textLightBrown,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _currentLocation!,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: textDarkBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
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
                color: afropeepGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: afropeepGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: afropeepGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your location helps us show you people nearby. We only show your city, never your exact location.',
                      style: GoogleFonts.montserrat(
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
