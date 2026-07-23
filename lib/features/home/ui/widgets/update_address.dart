import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/bloc/user/user_bloc.dart';
import '../../../../common/constants/app_colors.dart';
import '../../../../common/constants/constants.dart';
import '../../../../common/routes/route_name.dart';
import '../../../../models/user_model.dart';
import '../../../../services/location_privacy_service.dart';
import '../../bloc/searchuser_bloc.dart';
import 'subscription_dialog.dart';

class UpdateAddressWidget extends StatefulWidget {
  const UpdateAddressWidget({
    required this.currentUser,
    required this.hasSubscription,
    required this.items,
    this.compact = false,
    super.key,
  });
  final UserModel currentUser;
  final bool hasSubscription;
  final Map items;
  final bool compact;

  @override
  State<UpdateAddressWidget> createState() => _UpdateAddressWidgetState();
}

class _UpdateAddressWidgetState extends State<UpdateAddressWidget> {
  Map<dynamic, dynamic> selectedLocation = {};
  bool _saving = false;
  bool _showUpdatedCue = false;
  Timer? _updatedCueTimer;

  @override
  void initState() {
    // GeoJSON-style [lng, lat] to match UpdateLocation / Set location payload.
    selectedLocation['address'] = widget.currentUser.address;
    selectedLocation['position'] = {
      'coordinates': [
        widget.currentUser.coordinates?['longitude'],
        widget.currentUser.coordinates?['latitude'],
      ],
    };
    super.initState();
  }

  @override
  void dispose() {
    _updatedCueTimer?.cancel();
    super.dispose();
  }

  void _flashUpdatedCue() {
    _updatedCueTimer?.cancel();
    setState(() => _showUpdatedCue = true);
    _updatedCueTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showUpdatedCue = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color chevronColor =
        isDark ? AppColors.primaryGreenLight : AppColors.primaryGreen;
    final Color labelColor = isDark
        ? scheme.onSurface.withValues(alpha: 0.78)
        : const Color(0xFF505050);
    final Color addressColor = scheme.onSurface;
    final String addressLine = (widget.currentUser.address ?? '').trim().isEmpty
        ? 'Tap to search or choose your area'.tr()
        : widget.currentUser.address!.trim();

    return Card(
      child: ExpansionTile(
        iconColor: chevronColor,
        collapsedIconColor: chevronColor,
        textColor: AppColors.primaryGreen,
        tilePadding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 10 : 14,
          vertical: widget.compact ? 4 : 6,
        ),
        trailing: Icon(
          Icons.arrow_drop_down,
          size: 28,
          color: chevronColor,
        ),
        leading: Icon(
          Icons.location_on_outlined,
          color: AppColors.primaryGreen,
          size: widget.compact ? 22 : 24,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Current location:'.tr(),
              style: TextStyle(
                fontSize: widget.compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    addressLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: addressColor,
                      fontSize: widget.compact ? 15 : 15,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _showUpdatedCue ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            children: <Widget>[
              Icon(
                _showUpdatedCue ? Icons.check : Icons.edit_outlined,
                size: 15,
                color: AppColors.primaryGreen.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _showUpdatedCue
                      ? 'Area updated'
                      : 'Search or update your area'.tr(),
                  style: TextStyle(
                    fontSize: widget.compact ? 12 : 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: widget.compact ? 10 : 15,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.location_on,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                InkWell(
                  onTap: _saving
                      ? null
                      : () async {
                          if (widget.hasSubscription) {
                            final Object? address = await Navigator.pushNamed(
                              context,
                              RouteName.updateLocationScreen,
                              arguments: selectedLocation,
                            );
                            if (!context.mounted) return;
                            if (address is Map) {
                              await _persistAddress(
                                Map<dynamic, dynamic>.from(address),
                              );
                            }
                          } else {
                            await showSubscriptionDialog(
                              context: context,
                              currentUser: widget.currentUser,
                              items: widget.items,
                            );
                          }
                        },
                  child: Text(
                    'Change location'.tr().toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  /// Persist once, refresh discovery, show inline cue (no snackbar).
  Future<void> _persistAddress(Map<dynamic, dynamic> address) async {
    final Object? position = address['position'];
    final Object? coordsRaw = position is Map ? position['coordinates'] : null;
    if (coordsRaw is! List || coordsRaw.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not read that location. Try again.'.tr(),
            style: GoogleFonts.montserrat(),
          ),
        ),
      );
      return;
    }

    final double? lng = (coordsRaw[0] as num?)?.toDouble();
    final double? lat = (coordsRaw[1] as num?)?.toDouble();
    final String label = (address['address']?.toString() ?? '').trim();
    if (lat == null || lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not read that location. Try again.'.tr(),
            style: GoogleFonts.montserrat(),
          ),
        ),
      );
      return;
    }

    final String uid = widget.currentUser.id ?? '';
    if (uid.isEmpty) return;

    setState(() => _saving = true);
    try {
      final String savedLabel = label.isEmpty ? 'Selected location' : label;
      await firebaseFireStoreInstance.collection('users').doc(uid).update({
        'location': {
          'latitude': lat,
          'longitude': lng,
          'address': savedLabel,
        },
        'latitude': lat,
        'longitude': lng,
        'geoHash': LocationPrivacyService.generateGeoHash(
          lat,
          lng,
          LocationPrecision.medium,
        ),
      });

      // latitude/longitude on UserModel are final — reload so discovery
      // filters around the new coords, not the stale in-memory values.
      final snap =
          await firebaseFireStoreInstance.collection('users').doc(uid).get();
      if (!mounted) return;

      final UserModel discoveryUser =
          snap.exists ? UserModel.fromDocument(snap) : widget.currentUser;

      // Push fresh coords into UserBloc — latitude/longitude on [widget.currentUser]
      // are final, so Apply filters / HomeController would otherwise keep scanning
      // the previous city.
      if (mounted) {
        context.read<UserBloc>().add(UserDataUpdated(discoveryUser));
      }

      setState(() {
        widget.currentUser.address = savedLabel;
        selectedLocation = {
          'address': savedLabel,
          'position': {
            'coordinates': [lng, lat],
          },
        };
        _saving = false;
      });
      _flashUpdatedCue();

      context.read<SearchUserBloc>().add(
            LoadUserEvent(currentUser: discoveryUser),
          );
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save location. Try again.'.tr(),
            style: GoogleFonts.montserrat(),
          ),
        ),
      );
    }
  }
}
