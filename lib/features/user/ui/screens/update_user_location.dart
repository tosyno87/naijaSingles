import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../common/bloc/theme/theme_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/data/repo/user_location_repo.dart';
import '../../../../common/widgets/afropeep_primary_button.dart';
import '../../../../common/widgets/hookup_circularbar.dart';
import '../../../../config/app_config.dart';
import '../widgets/location_savedailog.dart';
import 'place_search_page.dart';

/// Hinge-style location picker: full-bleed map + bottom sheet.
/// One primary **Set location** action pops `{ position, address }` — no
/// intermediate "Save changes?" dialog.
class UpdateLocation extends StatefulWidget {
  const UpdateLocation({required this.selectedLocation, super.key});
  final Map? selectedLocation;

  @override
  UpdateLocationState createState() => UpdateLocationState();
}

class UpdateLocationState extends State<UpdateLocation> {
  double? latitude;
  double? longitude;
  String? _placeLabel;
  bool _loadingGps = true;
  bool _saving = false;
  GoogleMapController? googleMapController;
  int _pinLabelSeq = 0;

  String get kGoogleApiKey => googleMapsKey;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      final Map? selected = widget.selectedLocation;
      if (selected != null && selected.isNotEmpty) {
        final dynamic coords = selected['position']?['coordinates'];
        if (coords is List && coords.length >= 2) {
          // This flow standardizes on GeoJSON [longitude, latitude]
          // (see UpdateAddressWidget / Set location payload). Do not guess
          // order from numeric ranges — e.g. Lagos [3.38, 6.52] is valid
          // as both lat-first and lng-first under that heuristic.
          final double lng = (coords[0] as num).toDouble();
          final double lat = (coords[1] as num).toDouble();
          setState(() {
            latitude = lat;
            longitude = lng;
            _placeLabel = selected['address']?.toString();
            _loadingGps = false;
          });
          return;
        }
      }

      final Map<dynamic, dynamic>? updateAddress =
          await UserLocationReporistoryImpl().getLocationCoordinates();
      if (!mounted) return;
      if (updateAddress == null) {
        setState(() => _loadingGps = false);
        return;
      }
      setState(() {
        latitude = (updateAddress['latitude'] as num?)?.toDouble();
        longitude = (updateAddress['longitude'] as num?)?.toDouble();
        final Object? name = updateAddress['PlaceName'];
        _placeLabel = name is String && name.isNotEmpty ? name : null;
        _loadingGps = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loadingGps = false);
    }
  }

  LatLng? get _cameraTarget {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingGps = true);
    try {
      final Map<dynamic, dynamic>? updateAddress =
          await UserLocationReporistoryImpl().getLocationCoordinates();
      if (!mounted) return;
      if (updateAddress == null) {
        setState(() => _loadingGps = false);
        return;
      }
      final double? lat = (updateAddress['latitude'] as num?)?.toDouble();
      final double? lng = (updateAddress['longitude'] as num?)?.toDouble();
      setState(() {
        latitude = lat;
        longitude = lng;
        final Object? name = updateAddress['PlaceName'];
        _placeLabel = name is String && name.isNotEmpty ? name : null;
        _loadingGps = false;
      });
      if (lat != null && lng != null) {
        await googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lng), zoom: 16),
          ),
        );
      }
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _loadingGps = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openPlaceSearch() async {
    if (kGoogleApiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Maps API key not configured'),
        ),
      );
      return;
    }

    try {
      final PlaceSuggestion? suggestion =
          await Navigator.of(context).push<PlaceSuggestion>(
        MaterialPageRoute<PlaceSuggestion>(
          builder: (_) => const PlaceSearchPage(),
        ),
      );
      if (suggestion == null || !mounted) return;

      final String label = suggestion.description.trim();
      double? lat;
      double? lng;
      String resolvedLabel = label;

      // Prefer privacy-aware PlaceName from details/geocode over raw prediction text
      // (predictions can be street-level).
      if (suggestion.placeId.isNotEmpty) {
        final Map<String, dynamic>? details =
            await UserLocationReporistoryImpl()
                .placeDetailsLatLng(suggestion.placeId);
        lat = (details?['latitude'] as num?)?.toDouble();
        lng = (details?['longitude'] as num?)?.toDouble();
        final String? formatted = details?['PlaceName']?.toString();
        if (formatted != null && formatted.isNotEmpty) {
          resolvedLabel = formatted;
        }
      }

      // Details can fail (key restrictions / billing). Fall back to Geocoding.
      if ((lat == null || lng == null) && label.isNotEmpty) {
        final Map<String, dynamic>? geo =
            await UserLocationReporistoryImpl().geocodeAddress(label);
        lat = (geo?['latitude'] as num?)?.toDouble();
        lng = (geo?['longitude'] as num?)?.toDouble();
        final String? geoName = geo?['PlaceName']?.toString();
        if (geoName != null && geoName.isNotEmpty) {
          resolvedLabel = geoName;
        }
      }

      // If details kept street coords but we have a city label, snap to city.
      if (lat != null &&
          lng != null &&
          resolvedLabel.isNotEmpty &&
          RegExp(r'\d').hasMatch(label) &&
          !RegExp(r'\d').hasMatch(resolvedLabel)) {
        final Map<String, dynamic>? city =
            await UserLocationReporistoryImpl().geocodeAddress(resolvedLabel);
        final double? cityLat = (city?['latitude'] as num?)?.toDouble();
        final double? cityLng = (city?['longitude'] as num?)?.toDouble();
        if (cityLat != null && cityLng != null) {
          lat = cityLat;
          lng = cityLng;
        }
      }

      if (!mounted) return;
      if (lat == null || lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not resolve that place. Try another search or drop a pin.',
            ),
          ),
        );
        return;
      }

      setState(() {
        latitude = lat;
        longitude = lng;
        _placeLabel = resolvedLabel.isNotEmpty ? resolvedLabel : _placeLabel;
      });

      await googleMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 16),
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Place search failed. Try again or use the map pin.',
          ),
        ),
      );
    }
  }

  /// Single confirm: build payload and pop — no "Save changes?" dialog.
  Future<void> _setLocation() async {
    if (latitude == null || longitude == null || _saving) return;
    setState(() => _saving = true);
    try {
      String label = _placeLabel?.trim() ?? '';
      if (label.isEmpty) {
        label = await getAddress(latitude, longitude);
      }
      if (label.trim().isEmpty) {
        label =
            'Selected location (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})';
      }

      final Map<String, dynamic> result = <String, dynamic>{
        'position': <String, dynamic>{
          'coordinates': <double>[longitude!, latitude!],
        },
        'address': label,
      };
      if (!mounted) return;
      Navigator.pop(context, result);
    } on Object {
      if (!mounted) return;
      // Still allow confirm with coordinates if labeling failed.
      Navigator.pop(context, <String, dynamic>{
        'position': <String, dynamic>{
          'coordinates': <double>[longitude!, latitude!],
        },
        'address': (_placeLabel?.trim().isNotEmpty ?? false)
            ? _placeLabel!.trim()
            : 'Selected location',
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _refreshLabelForPin(LatLng loc) async {
    final int seq = ++_pinLabelSeq;
    setState(() {
      latitude = loc.latitude;
      longitude = loc.longitude;
    });
    try {
      final String label = await getAddress(loc.latitude, loc.longitude);
      if (!mounted || seq != _pinLabelSeq) return;
      // Ignore stale reverse-geocode if the pin moved again.
      if (latitude != loc.latitude || longitude != loc.longitude) return;
      setState(() => _placeLabel = label);
    } on Object {
      // Keep pin; label can stay stale or use fallback on Set.
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.watch<ThemeBloc>().isDarkMode;
    final Color scaffoldBg =
        isDark ? const Color(0xFF121212) : AppColors.backgroundColor;
    final Color sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color onSheet = isDark ? Colors.white : AppColors.textPrimary;
    final Color muted = isDark ? Colors.white70 : AppColors.textSecondary;
    final LatLng? target = _cameraTarget;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: onSheet, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose location'.tr(),
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: onSheet,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingGps && target == null
          ? const Center(child: Hookup4uBar())
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (kGoogleApiKey.isEmpty || target == null)
                        ColoredBox(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFE8E8E8),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                kGoogleApiKey.isEmpty
                                    ? 'Map unavailable — Google Maps API key not configured'
                                    : 'Fetching your location…',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(color: muted),
                              ),
                            ),
                          ),
                        )
                      else
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: target,
                            zoom: 16,
                          ),
                          onMapCreated: (GoogleMapController c) {
                            googleMapController = c;
                          },
                          myLocationEnabled: false,
                          zoomControlsEnabled: false,
                          compassEnabled: false,
                          mapToolbarEnabled: false,
                          markers: <Marker>{
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: LatLng(latitude!, longitude!),
                              draggable: true,
                              onDragEnd: (LatLng loc) {
                                unawaited(_refreshLabelForPin(loc));
                              },
                            ),
                          },
                          onLongPress: (LatLng position) {
                            unawaited(_refreshLabelForPin(position));
                            unawaited(
                              googleMapController?.animateCamera(
                                CameraUpdate.newLatLng(position),
                              ),
                            );
                          },
                        ),
                      if (_loadingGps)
                        const Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Center(child: Hookup4uBar()),
                        ),
                    ],
                  ),
                ),
                Material(
                  color: sheetBg,
                  elevation: 8,
                  shadowColor: Colors.black26,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (_placeLabel?.isNotEmpty ?? false)
                                ? _placeLabel!
                                : 'Drop a pin or search for a place',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: onSheet,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _openPlaceSearch,
                            icon: const Icon(Icons.search, size: 20),
                            label: Text(
                              'Search for a place',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryGreen,
                              side: const BorderSide(
                                color: AppColors.primaryGreen,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed:
                                _loadingGps ? null : _useCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 18),
                            label: Text(
                              'Use current location',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          AfropeepPrimaryButton(
                            text: 'Update Location'.tr(),
                            isLoading: _saving,
                            onPressed: (latitude != null && longitude != null)
                                ? _setLocation
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
