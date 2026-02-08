import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // New Afropeep theme colors
  static const Color backgroundColor = Colors.white; // Clean white
  static const Color primaryColor = Color(0xFF008037); // Deep green
  static const Color cardColor = Colors.white; // White cards with shadows
  static const Color successColor = Color(0xFF4CAF50); // Green for success
  static const Color errorColor = Color(0xFFFF5A5F); // Red for errors
  static const Color textPrimary = Color(0xFF3E1F0D); // Deep brown
  static const Color textSecondary = Color(0xFF666666); // Medium gray
  static const Color textLight = Color(0xFF999999); // Light gray

  bool _isLoading = true;
  bool _isUpdatingLocation = false;
  bool _preciseLocationEnabled = true;
  bool _showLocationInProfile = true;
  bool _allowLocationBasedMatching = true;
  double _maxDistance = 31; // miles (converted from 50km)
  String _currentLocation = 'Unknown';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadLocationSettings();
  }

  Future<void> _loadLocationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Load settings from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _preciseLocationEnabled =
          prefs.getBool('precise_location_enabled') ?? true;
      _showLocationInProfile =
          prefs.getBool('show_location_in_profile') ?? true;
      _allowLocationBasedMatching =
          prefs.getBool('allow_location_matching') ?? true;
      _maxDistance = prefs.getDouble('max_distance') ?? 31.0;

      // Load current location
      await _getCurrentLocation();

      setState(() => _isLoading = false);
    } catch (e) {
      log('Error loading location settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentLocation = 'Location access denied');
        return;
      }

      if (permission == LocationPermission.denied) {
        setState(() => _currentLocation = 'Location permission required');
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentLocation = '${place.locality}, ${place.administrativeArea}';
        });
      }
    } catch (e) {
      log('Error getting current location: $e');
      setState(() => _currentLocation = 'Unable to get location');
    }
  }

  Future<void> _updateLocationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('precise_location_enabled', _preciseLocationEnabled);
      await prefs.setBool('show_location_in_profile', _showLocationInProfile);
      await prefs.setBool(
        'allow_location_matching',
        _allowLocationBasedMatching,
      );
      await prefs.setDouble('max_distance', _maxDistance);

      // Update user document in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'locationSettings': {
          'preciseLocationEnabled': _preciseLocationEnabled,
          'showLocationInProfile': _showLocationInProfile,
          'allowLocationBasedMatching': _allowLocationBasedMatching,
          'maxDistance': _maxDistance,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location settings updated successfully',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      log('Error updating location settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update location settings',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshLocation() async {
    setState(() => _isUpdatingLocation = true);
    await _getCurrentLocation();
    setState(() => _isUpdatingLocation = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Location Settings',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _updateLocationSettings,
              child: Text(
                'Save',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    _buildHeaderSection(),
                    const SizedBox(height: 24),

                    // Current Location
                    _buildCurrentLocationSection(),
                    const SizedBox(height: 24),

                    // Location Permissions
                    _buildLocationPermissionsSection(),
                    const SizedBox(height: 24),

                    // Matching Preferences
                    _buildMatchingPreferencesSection(),
                    const SizedBox(height: 24),

                    // Privacy Settings
                    _buildPrivacySettingsSection(),
                    const SizedBox(height: 24),

                    // Location Info
                    _buildLocationInfoSection(),
                  ],
                ),
              ),
      );

  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading location settings...',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildHeaderSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                size: 40,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Location Settings',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your location preferences to find better matches nearby and control your privacy.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildCurrentLocationSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.my_location, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Current Location',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentLocation,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentPosition != null
                            ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                            : 'Coordinates not available',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isUpdatingLocation ? null : _refreshLocation,
                  icon: _isUpdatingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(
                    _isUpdatingLocation ? 'Updating...' : 'Refresh',
                    style: GoogleFonts.montserrat(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildLocationPermissionsSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Permissions',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Precise Location',
              subtitle: 'Use GPS for accurate location matching',
              value: _preciseLocationEnabled,
              onChanged: (value) {
                setState(() => _preciseLocationEnabled = value);
              },
              icon: Icons.gps_fixed,
            ),
          ],
        ),
      );

  Widget _buildMatchingPreferencesSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Matching Preferences',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Location-Based Matching',
              subtitle: 'Find matches based on your location',
              value: _allowLocationBasedMatching,
              onChanged: (value) {
                setState(() => _allowLocationBasedMatching = value);
              },
              icon: Icons.people_alt,
            ),
            const SizedBox(height: 20),
            Text(
              'Maximum Distance',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _maxDistance,
                    min: 1,
                    max: 62, // 100km = 62 miles
                    divisions: 99,
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withOpacity(0.3),
                    onChanged: _allowLocationBasedMatching
                        ? (value) {
                            setState(() => _maxDistance = value);
                          }
                        : null,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_maxDistance.round()} mi',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Show potential matches within ${_maxDistance.round()} miles of your location',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _buildPrivacySettingsSection() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Settings',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Show Location in Profile',
              subtitle: 'Display your city/area in your profile',
              value: _showLocationInProfile,
              onChanged: (value) {
                setState(() => _showLocationInProfile = value);
              },
              icon: Icons.visibility,
            ),
          ],
        ),
      );

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) =>
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: primaryColor,
            activeTrackColor: primaryColor.withOpacity(0.3),
          ),
        ],
      );

  Widget _buildLocationInfoSection() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Location Privacy',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoItem(
              '🔒 Your exact location is never shared with other users',
            ),
            _buildInfoItem('📍 Only approximate distance is shown to matches'),
            _buildInfoItem('🎯 Location data helps improve match quality'),
            _buildInfoItem('⚙️ You can disable location features anytime'),
          ],
        ),
      );

  Widget _buildInfoItem(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: textSecondary,
            height: 1.4,
          ),
        ),
      );
}
