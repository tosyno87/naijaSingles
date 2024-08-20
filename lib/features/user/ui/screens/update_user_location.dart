// ignore_for_file: use_build_context_synchronously, depend_on_referenced_packages

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:hookup4u2/common/constants/colors.dart';
import 'package:hookup4u2/common/widets/custom_button.dart';
import 'package:provider/provider.dart';

import '../../../../common/data/repo/user_location_repo.dart';
import '../../../../common/providers/theme_provider.dart';
import '../../../../common/widets/hookup_circularbar.dart';
import '../../../../config/app_config.dart';
import '../widgets/location_savedailog.dart';

class UpdateLocation extends StatefulWidget {
  final Map? selectedLocation;
  const UpdateLocation({super.key, required this.selectedLocation});
  @override
  UpdateLocationState createState() => UpdateLocationState();
}

class UpdateLocationState extends State<UpdateLocation> {
  final kGoogleApiKey = googleMapsKey;
  Map? _newAddress;
  double? latitude, longitude;
  // LatLng defaultLocation =
  //     const LatLng(33.501324, -111.925278); //Scottsdale, AZ, USA

  // UserModel currentUser;
  GoogleMapController? googleMapController;
  void onError(PlacesAutocompleteResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.errorMessage ?? 'Unknown error').tr(),
      ),
    );
  }

  @override
  void initState() {
    updateLoc();

    super.initState();
  }

  Future<void> updateLoc() async {
    await UserLocationReporistoryImpl()
        .getLocationCoordinates()
        .then((updateAddress) {
      setState(() {
        _newAddress = updateAddress!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        if (latitude != null && longitude != null) {
          Map<String, dynamic>? a =
              await showLocationDialog(context, latitude, longitude);

          navigator.pop(a);
        }
        return;
      },
      child: Scaffold(
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(left: 33),
            child: CustomButton(
              active: true,
              color: Colors.white,
              onTap: () async {
                if (latitude != null && longitude != null) {
                  var a =
                      await showLocationDialog(context, latitude, longitude);

                  Navigator.pop(context, a);
                }
              },
              text: 'Update Location'.tr().toString(),
            ),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Use Current Location?'.tr().toString(),
                              style: TextStyle(
                                  fontSize: 20,
                                  color: themeProvider.isDarkMode
                                      ? Colors.white70
                                      : Colors.black87),
                            ),
                            const SizedBox(height: 8.0),
                            Column(
                              children: [
                                Text(
                                  'Do you want to use your current location?'
                                      .tr()
                                      .toString(),
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Text(
                                  _newAddress != null
                                      ? _newAddress!['PlaceName'] ??
                                          'Fetching..'.toString()
                                      : 'Unable to load...',
                                ).tr(),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close the dialog
                                  },
                                  child: Text(
                                    'No'.tr().toString(),
                                    style: TextStyle(color: primaryColor),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    googleMapController?.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: LatLng(
                                            _newAddress?['latitude'],
                                            _newAddress?['longitude'],
                                          ),
                                          zoom: 16.0,
                                        ),
                                      ),
                                    );
                                    setState(() {
                                      latitude = _newAddress?['latitude'];
                                      longitude = _newAddress?['longitude'];
                                    });
                                    Navigator.pop(context); // Close the dialog
                                  },
                                  child: Text(
                                    'Yes'.tr().toString(),
                                    style: TextStyle(color: primaryColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              title: Text(
                "Choose location".tr().toString(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              // ignore: unnecessary_null_comparison
              subtitle: Text(_newAddress != null
                      ? _newAddress!['PlaceName'] ??
                          'Fetching..'.tr().toString()
                      : 'Unable to load...'.tr().toString())
                  .tr(),
            ),
            actions: [
              IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () async {
                    try {
                      Prediction? prediction = await PlacesAutocomplete.show(
                          offset: 0,
                          types: [],
                          strictbounds: false,
                          context: context,
                          apiKey: kGoogleApiKey,
                          mode: Mode.overlay,
                          language: "es",
                          onError: onError,
                          components: []);
                      if (prediction != null) {
                        final GoogleMapsPlaces places =
                            GoogleMapsPlaces(apiKey: kGoogleApiKey);
                        PlacesDetailsResponse response = await places
                            .getDetailsByPlaceId(prediction.placeId!);

                        final lat = response.result.geometry?.location.lat;
                        final lng = response.result.geometry?.location.lng;

                        googleMapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(lat!, lng!),
                              zoom: 16.0,
                            ),
                          ),
                        );

                        setState(() {
                          latitude = lat;
                          longitude = lng;
                        });
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                        ),
                      );

                      return;
                    }
                  })
            ],
          ),
          body: _newAddress != null
              ? SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: Stack(
                          children: [
                            GoogleMap(
                              markers: latitude == null || longitude == null
                                  ? {
                                      Marker(
                                          markerId: const MarkerId('randomId'),
                                          position: widget.selectedLocation
                                                      ?.isEmpty ??
                                                  true
                                              ? LatLng(
                                                  _newAddress?['latitude'],
                                                  _newAddress?['longitude'],
                                                )
                                              : LatLng(
                                                  widget.selectedLocation?[
                                                          'position']
                                                      ['coordinates'][1],
                                                  widget.selectedLocation?[
                                                          'position']
                                                      ['coordinates'][0]),
                                          onTap: () {
                                            showDialog(
                                              barrierColor: Colors.transparent,
                                              context: context,
                                              builder: (BuildContext context) {
                                                if (widget.selectedLocation
                                                        ?.isEmpty ??
                                                    true) {
                                                  latitude =
                                                      _newAddress?['latitude'];
                                                  longitude =
                                                      _newAddress?['longitude'];
                                                  return FutureBuilder(
                                                      future: getAddress(
                                                          latitude, longitude),
                                                      builder:
                                                          (BuildContext ctx,
                                                              AsyncSnapshot
                                                                  snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return AlertDialog(
                                                            title: const Center(
                                                                child:
                                                                    Hookup4uBar()),
                                                            content: Text(
                                                              'loading...'
                                                                  .tr()
                                                                  .toString(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return AlertDialog(
                                                            title: Text(
                                                                '${snapshot.error}'),
                                                          );
                                                        } else if (snapshot
                                                            .hasData) {
                                                          return AlertDialog(
                                                            title: Text(
                                                                '${snapshot.data}'),
                                                          );
                                                        }
                                                        return Container();
                                                      });
                                                }
                                                return AlertDialog(
                                                  title: Text(
                                                          '${widget.selectedLocation?['address'] ?? 'loading...'}')
                                                      .tr(),
                                                );
                                              },
                                            );
                                          }),
                                    }
                                  : {
                                      Marker(
                                          onDragEnd: (LatLng loc) {
                                            setState(() {
                                              latitude = loc.latitude;
                                              longitude = loc.longitude;
                                            });

                                            googleMapController?.animateCamera(
                                              CameraUpdate.newCameraPosition(
                                                CameraPosition(
                                                  target: LatLng(loc.latitude,
                                                      loc.longitude),
                                                  zoom: 16.0,
                                                ),
                                              ),
                                            );
                                          },
                                          consumeTapEvents: true,
                                          onTap: () async {
                                            googleMapController?.animateCamera(
                                                CameraUpdate.newCameraPosition(
                                                    CameraPosition(
                                              target:
                                                  LatLng(latitude!, longitude!),
                                              zoom: 16.0,
                                            )));
                                            showAddressDialog(
                                                context, latitude!, longitude!);
                                          },
                                          draggable: true,
                                          markerId: const MarkerId('randomId'),
                                          position:
                                              LatLng(latitude!, longitude!))
                                    },
                              mapType: MapType.normal,
                              initialCameraPosition: CameraPosition(
                                  target: widget.selectedLocation?.isEmpty ??
                                          true
                                      ? LatLng(
                                          _newAddress?['latitude'],
                                          _newAddress?['longitude'],
                                        )
                                      : LatLng(
                                          widget.selectedLocation?['position']
                                              ['coordinates'][0],
                                          widget.selectedLocation?['position']
                                              ['coordinates'][1]),
                                  zoom: 16),
                              onMapCreated: (GoogleMapController controller) {
                                googleMapController = controller;
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomGesturesEnabled: true,
                              zoomControlsEnabled: false,
                              buildingsEnabled: true,
                              onLongPress: (position) {
                                setState(() {
                                  latitude = position.latitude;
                                  longitude = position.longitude;
                                });
                                googleMapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: LatLng(position.latitude,
                                          position.longitude),
                                      zoom: 16.0,
                                    ),
                                  ),
                                );
                              },
                              mapToolbarEnabled: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const Hookup4uBar()),
    );
  }
}
