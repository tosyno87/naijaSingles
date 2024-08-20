import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hookup4u2/models/user_model.dart';

import '../../common/constants/colors.dart';
import '../payment/ui/products.dart';

class FreeUserMapScreen extends StatelessWidget {
  final UserModel currentUser;
  const FreeUserMapScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          GoogleMapWidget(
            currentUser: currentUser,
          ), // Display the Google Map as the background
          PremiumDialog(
              currentUser: currentUser), // Display the custom dialog on top
        ],
      ),
    );
  }
}

class GoogleMapWidget extends StatefulWidget {
  final UserModel currentUser;
  const GoogleMapWidget({super.key, required this.currentUser});

  @override
  GoogleMapWidgetState createState() => GoogleMapWidgetState();
}

class GoogleMapWidgetState extends State<GoogleMapWidget> {
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapToolbarEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      scrollGesturesEnabled: false,
      initialCameraPosition: CameraPosition(
        target: LatLng(
            widget.currentUser.latitude!,
            widget.currentUser
                .longitude!), // Replace with your desired map coordinates
        zoom: 15.0,
      ),
    );
  }
}

class PremiumDialog extends StatelessWidget {
  final UserModel currentUser;
  const PremiumDialog({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: InkWell(
          child: Container(
            color: Colors.white.withOpacity(.3),
            child: Dialog(
              insetAnimationCurve: Curves.bounceInOut,
              insetAnimationDuration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * .55,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 50,
                      color: primaryColor,
                    ),
                    Text(
                      'This feature requires a subscription. Do you want to subscribe to our plan?'
                          .tr()
                          .toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: secondryColor,
                          fontSize: 20),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.lock_outline,
                        size: 120,
                        color: primaryColor,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    Products(currentUser, null, const {})));
                      },
                      style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(
                              primaryColor.withOpacity(0.9))),
                      child: Text(
                        'Upgrade Now'.tr().toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          onTap: () => {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Products(currentUser, null, const {})))
              }),
    );
  }
}
