import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hookup4u2/common/constants/colors.dart';
import 'package:hookup4u2/features/explore/bloc/explore_map_bloc.dart';
import 'package:hookup4u2/features/explore/no_user.dart';
// import 'package:hookup4u2/features/explore/premium_map.dart';
import 'package:hookup4u2/features/street_view/street_view.dart';
import 'package:provider/provider.dart';

import '../../common/data/repo/user_location_repo.dart';
import '../../common/providers/theme_provider.dart';
import '../../models/user_model.dart';

class ExploreMapWidget extends StatefulWidget {
  final UserModel currentUser;
  final bool isPuchased;
  const ExploreMapWidget(
      {super.key, required this.currentUser, required this.isPuchased});

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

  void getCurrentAdddressName() async {
    currentCoordinates = LatLng(
        widget.currentUser.currentCoordinates?['latitude'],
        widget.currentUser.currentCoordinates?['longitude']);
    currentAddressName = await getAddress(
            currentCoordinates?.latitude, currentCoordinates?.longitude)
        .whenComplete(() {
      context.read<SearchUserForMapBloc>().add(LoadUserForMapEvent(
            currentUser: widget.currentUser,
          ));
    });
    log("name is $currentAddressName");
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
    final themeProvider = Provider.of<ThemeProvider>(context);

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
                return Center(
                  child: SizedBox(
                    width: 150,
                    child: Card(
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              height: 25,
                              width: 25,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(primaryColor),
                              ),
                            ),
                            const Text(
                              "Searching...",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
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
                  "Error to load data.".tr().toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black54,
                      fontStyle: FontStyle.normal,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                      fontSize: 18),
                ));
              }

              if (state is SearchUserLoadUserForMapState) {
                log("users is ${state.users.length}");
                return state.users.isEmpty
                    ? NoUserFoundWidget(
                        currentUser: widget.currentUser,
                        currentAddressName: currentAddressName,
                      )
                    : StreetViewPanoramaInit(
                        user: state.users,
                        currentAddressName: currentAddressName,
                        fromSingleuser: false,
                        currentUser: widget.currentUser);
              }
              return Container();
            },
          )

          // : FreeUserMapScreen(
          //     currentUser: widget.currentUser,
          //   )
          ),
    );
  }
}
