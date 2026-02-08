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
import '../../common/constants/colors.dart';
import '../../common/data/repo/user_location_repo.dart';
import '../../models/user_model.dart';
import 'bloc/explore_map_bloc.dart';

class ExploreMapWidget extends StatefulWidget {
  const ExploreMapWidget({
    required this.currentUser,
    required this.isPuchased,
    super.key,
  });
  final UserModel currentUser;
  final bool isPuchased;

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
    getCurrentAdddressName();
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
    ).whenComplete(() {
      context.read<SearchUserForMapBloc>().add(
            LoadUserForMapEvent(
              currentUser: widget.currentUser,
            ),
          );
    });
    log('name is $currentAddressName');
    setState(() {});
  }

  Future getAddress(lat, lng) async {
    try {
      final address = await UserLocationReporistoryImpl()
          .getReverseGeocodingData(lat: lat, lng: lng);
      return address['subLocality'];
    } on SocketException {
      throw 'No internet connection'.tr().toString();
    } catch (e) {
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

            //  widget.isPuchased ?

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
                              valueColor: AlwaysStoppedAnimation(primaryColor),
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
                    color: isDarkMode
                        ? Colors.white
                        : Colors.black54,
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
                            color: primaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No users found in this area',
                            style: TextStyle(
                              fontSize: 18,
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try expanding your search radius',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      // Simple map view instead of street view
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
