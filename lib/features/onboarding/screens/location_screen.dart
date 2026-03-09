import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../common/utils/app_logger.dart';
import '../bloc/onboarding_bloc.dart';
import '../onboarding_theme.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String? _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = context.read<OnboardingBloc>().state.data;

      if (data?.locationName?.isNotEmpty ?? false) {
        setState(() {
          _currentLocation = data?.locationName;
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showPermissionDeniedDialog();
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        String location = '';

        if (place.country == 'United States') {
          location = '${place.locality}, ${place.administrativeArea}';
        } else if (place.country == 'Canada') {
          location = '${place.locality}, ${place.administrativeArea}';
        } else {
          location = '${place.locality}, ${place.country}';
        }

        setState(() {
          _currentLocation = location;
          _isLoadingLocation = false;
        });

        if (!mounted) return;

        context.read<OnboardingBloc>().add(
              OnboardingLocationUpdated(
                position.latitude,
                position.longitude,
                location,
              ),
            );

        AppLogger.info('LocationScreen: GPS location set to "$location"');
      }
    } on Object catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      AppLogger.error('Error getting location', error: e);
    }
  }

  void _showLocationServiceDialog() {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OnboardingTheme.fieldRadius),
          ),
          title: Text(
            'Location Services Disabled',
            style: OnboardingTheme.sectionLabelStyle,
          ),
          content: Text(
            'Location is required to find matches nearby. Please enable location services in your device settings.',
            style: OnboardingTheme.subtitleStyle.copyWith(
              color: OnboardingTheme.sectionLabelColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: OnboardingTheme.subtitleColor,
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
                      backgroundColor: OnboardingTheme.primaryGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OnboardingTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    unawaited(
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OnboardingTheme.fieldRadius),
          ),
          title: Text(
            'Location Permission Required',
            style: OnboardingTheme.sectionLabelStyle,
          ),
          content: Text(
            'Location is required to find matches nearby. Please enable location permissions in your device settings to continue.',
            style: OnboardingTheme.subtitleStyle.copyWith(
              color: OnboardingTheme.sectionLabelColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.montserrat(
                  color: OnboardingTheme.subtitleColor,
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
                      backgroundColor: OnboardingTheme.primaryGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: OnboardingTheme.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OnboardingTheme.constrainedContent(
        child: SingleChildScrollView(
          padding: OnboardingTheme.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where are you located?',
                style: OnboardingTheme.titleStyle,
              ),
              const SizedBox(height: OnboardingTheme.titleToSubtitle),
              Text(
                'This helps us connect you with people nearby',
                style: OnboardingTheme.subtitleStyle,
              ),
              const SizedBox(height: OnboardingTheme.subtitleToField),
              SizedBox(
                width: double.infinity,
                height: OnboardingTheme.buttonHeight,
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
                    backgroundColor: OnboardingTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        OnboardingTheme.buttonRadius,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: OnboardingTheme.fieldToSection),
              if (_currentLocation != null) ...[
                Builder(
                  builder: (context) {
                    final location = _currentLocation;
                    if (location == null) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        OnboardingTheme.fieldContentPadding,
                      ),
                      decoration: BoxDecoration(
                        color: OnboardingTheme.primaryGreen
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          OnboardingTheme.fieldRadius,
                        ),
                        border: Border.all(
                          color: OnboardingTheme.primaryGreen
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: OnboardingTheme.primaryGreen,
                            size: OnboardingTheme.fieldIconSize,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Location',
                                  style: OnboardingTheme.helperStyle,
                                ),
                                Text(
                                  location,
                                  style:
                                      OnboardingTheme.fieldTextStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.check_circle,
                            color: OnboardingTheme.primaryGreen,
                            size: OnboardingTheme.fieldIconSize,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: OnboardingTheme.fieldToSection),
              ],
              Container(
                padding: const EdgeInsets.all(
                  OnboardingTheme.fieldContentPadding,
                ),
                decoration: BoxDecoration(
                  color: OnboardingTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(
                    OnboardingTheme.fieldRadius,
                  ),
                  border: Border.all(
                    color: OnboardingTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: OnboardingTheme.primaryGreen,
                      size: OnboardingTheme.fieldIconSize,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your location helps us show you people nearby. We only show your city, never your exact location.',
                        style: OnboardingTheme.helperStyle.copyWith(
                          color: OnboardingTheme.sectionLabelColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
