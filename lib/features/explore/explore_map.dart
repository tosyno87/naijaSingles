import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Removed no_user.dart import - file deleted
// import 'package:naijasingles/features/explore/premium_map.dart';
// Removed street view import - feature deleted

import '../../common/bloc/theme/theme_bloc.dart';
import '../../common/constants/app_colors.dart';
import '../../common/data/repo/user_location_repo.dart';
import '../../common/widgets/native_maps_gate.dart';
import '../../models/user_model.dart';
import 'bloc/explore_map_bloc.dart';

class ExploreMapWidget extends StatefulWidget {
  const ExploreMapWidget({
    required this.currentUser,
    required this.isPurchased,
    super.key,
  });
  final UserModel currentUser;
  final bool isPurchased;

  @override
  State<ExploreMapWidget> createState() => _ExploreMapWidgetState();
}

class _ExploreMapWidgetState extends State<ExploreMapWidget>
    with AutomaticKeepAliveClientMixin {
  LatLng? currentCoordinates;
  String currentAddressName = '';
  GoogleMapController? googleMapController;

  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    unawaited(getCurrentAdddressName());
    super.initState();
  }

// for getting current address

  Future<void> getCurrentAdddressName() async {
    currentCoordinates = LatLng(
      widget.currentUser.currentCoordinates?['latitude'],
      widget.currentUser.currentCoordinates?['longitude'],
    );
    currentAddressName = await getAddress(
      currentCoordinates?.latitude,
      currentCoordinates?.longitude,
    );
    if (!mounted) return;
    context.read<SearchUserForMapBloc>().add(
          LoadUserForMapEvent(
            currentUser: widget.currentUser,
          ),
        );
    log('name is $currentAddressName');
    setState(() {});
  }

  Future<String> getAddress(double? lat, double? lng) async {
    try {
      final address = await UserLocationReporistoryImpl()
          .getReverseGeocodingData(lat: lat ?? 0, lng: lng ?? 0);
      return (address['subLocality'] ?? '') as String;
    } on SocketException {
      throw Exception('No internet connection'.tr().toString());
    } on Object {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = context.watch<ThemeBloc>().isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child:

            //  widget.isPurchased ?

            BlocBuilder<SearchUserForMapBloc, SearchUserForMapState>(
          builder: (context, state) {
            if (state is SearchUserLoadingForMapState) {
              return const Center(
                child: SizedBox(
                  width: 150,
                  child: Card(
                    elevation: 10,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          SizedBox(
                            height: 25,
                            width: 25,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          Text(
                            'Searching...',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            if (state is SearchUserFailedForMapState) {
              return Center(
                child: Text(
                  'Error to load data.'.tr().toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black54,
                    fontStyle: FontStyle.normal,
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
                    fontSize: 18,
                  ),
                ),
              );
            }

            if (state is SearchUserLoadUserForMapState) {
              log('users is ${state.users.length}');
              return state.users.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: AppColors.primaryGreen,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No users found in this area',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try expanding your search radius',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : NativeMapsGate(
                      builder: (_) => GoogleMap(
                        // Native Maps SDK uses the platform key (iOS Secrets /
                        // Android manifest), not the Dart env Places key.
                        onMapCreated: (GoogleMapController controller) {
                          // Map initialization
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            widget.currentUser.latitude ?? 0.0,
                            widget.currentUser.longitude ?? 0.0,
                          ),
                          zoom: 14,
                        ),
                        markers: Set<Marker>.from(
                          state.users.map(
                            (user) => Marker(
                              markerId: MarkerId(user.id ?? ''),
                              position: LatLng(
                                user.latitude ?? 0.0,
                                user.longitude ?? 0.0,
                              ),
                              infoWindow: InfoWindow(
                                title: user.name,
                                snippet: '${user.age} years old',
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
            }
            return Container();
          },
        ),

        // : FreeUserMapScreen(
        //     currentUser: widget.currentUser,
        //   )
      ),
    );
  }
}
