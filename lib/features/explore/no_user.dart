import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../common/constants/colors.dart';
import '../../common/constants/constants.dart';
import '../../common/data/repo/user_search_repo.dart';
import '../../common/providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../street_view/street_view.dart';
import 'bloc/explore_map_bloc.dart';

class NoUserFoundWidget extends StatefulWidget {
  final UserModel currentUser;
  final String currentAddressName;
  const NoUserFoundWidget(
      {super.key, required this.currentUser, required this.currentAddressName});

  @override
  State<NoUserFoundWidget> createState() => _NoUserFoundWidgetState();
}

class _NoUserFoundWidgetState extends State<NoUserFoundWidget> {
  Location location = Location();
  LocationData? _lastLocation;

  @override
  void initState() {
    _currentLocationUpdate();
    super.initState();
  }

  void _currentLocationUpdate() async {
    var hasPermission = await location.hasPermission();
    if (hasPermission != PermissionStatus.granted) {
      await location.requestPermission();
    }

    if (hasPermission == PermissionStatus.granted ||
        hasPermission == PermissionStatus.grantedLimited) {
      await location.changeSettings(
        distanceFilter: 100,
        accuracy: LocationAccuracy.high,
      );
      location.onLocationChanged.listen((LocationData newLocation) async {
        if (_lastLocation == null) {
          if (mounted) {
            setState(() {
              _lastLocation = newLocation;
            });
          }

          return;
        }

        var displacement = UserSearchRepo.calculateDistance(
            widget.currentUser.currentCoordinates?['latitude'],
            widget.currentUser.currentCoordinates?['longitude'],
            newLocation.latitude,
            newLocation.longitude);
        log("displacement is $displacement");

        if (displacement >= 0.05) {
          String userId = firebaseAuthInstance.currentUser!.uid;

          // Create a reference to the user's document in Firestore.
          DocumentReference userDocRef =
              firebaseFireStoreInstance.collection('Users').doc(userId);

          // Update the user's current location.
          await userDocRef.update({
            'currentLocation': {
              'latitude': newLocation.latitude,
              'longitude': newLocation.longitude,
              'timestamp':
                  FieldValue.serverTimestamp(), // Optional: Server timestamp.
            },
          });
          if (mounted) {
            setState(() {
              context.read<SearchUserForMapBloc>().add(LoadUserForMapEvent(
                    currentUser: widget.currentUser,
                  ));
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Stack(children: [
      StreetViewPanoramaInit(
          user: const [],
          currentAddressName: widget.currentAddressName,
          fromSingleuser: false,
          currentUser: widget.currentUser),
      Align(
          alignment: Alignment.center,
          child: Dialog(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 40,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        "asset/hookup4u-Logo-BP.png",
                        fit: BoxFit.contain,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    "No nearby users found.".tr().toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black54,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    "To find more users,try switching your location or refreshing the page."
                        .tr()
                        .toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: themeProvider.isDarkMode
                          ? Colors.white
                          : Colors.black54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<SearchUserForMapBloc>()
                          .add(LoadUserForMapEvent(
                            currentUser: widget.currentUser,
                          ));
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          primaryColor), // Change button color
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              20.0), // Change button shape
                        ),
                      ),
                    ),
                    child: Text(
                      "Refresh".tr().toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              ),
            ),
          )),
    ]);
  }
}
